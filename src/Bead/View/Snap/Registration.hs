{-# LANGUAGE OverloadedStrings #-}
module Bead.View.Snap.Registration (
    createAdminUser
  , createUser
  , registrationRequest
  , finalizeRegistration
  ) where

-- Bead imports

import Bead.Controller.Logging as L

import qualified Bead.Controller.UserStories as S
import qualified Bead.Controller.Pages as P (Page(Login))
import Bead.Configuration (Config(..))
import Bead.View.Snap.Application
import Bead.View.Snap.Session
import Bead.View.Snap.HandlerUtils
import Bead.View.Snap.DataBridge
import Bead.View.Snap.ErrorPage
import Bead.View.Snap.RouteOf (requestRoute)
import Bead.View.Snap.EmailTemplate
import qualified Bead.Persistence.Persist as P (Persist(..), runPersist)

import Bead.View.Snap.Content hiding (
    BlazeTemplate, name, template, empty, method
  )

-- Haskell imports

import Data.Maybe (fromJust, isNothing)
import Data.String (fromString)
import Data.Time hiding (TimeZone)
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8)
import qualified Data.List as L
import qualified Data.ByteString.Char8 as B
import Network.Mail.Mime
import Text.Printf (printf)

-- Snap and Blaze imports

import Snap hiding (Config(..), get)
import Snap.Snaplet.Auth as A hiding (createUser)
import Snap.Snaplet.Auth.Backends.JsonFile (mkJsonAuthMgr)

import Text.Blaze (textTag)
import Text.Blaze.Html5 ((!))
import qualified Text.Blaze.Html5.Attributes as A hiding (title, rows, accept)
import Bead.View.Snap.I18N (IHtml)
import qualified Text.Blaze.Html5 as H

createUser :: P.Persist -> FilePath -> User -> String -> IO ()
createUser persist usersdb user password = do
  let name = usernameCata id $ u_username user
  mgr <- mkJsonAuthMgr usersdb
  pwd <- encryptPassword . ClearText . fromString $ password
  let authUser = defAuthUser {
      userLogin    = fromString name
    , userPassword = Just pwd
    }
  save mgr authUser
  createdUser <- lookupByLogin mgr (T.pack name)
  case createdUser of
    Nothing -> error "Nem jött létre felhasználó!"
    Just u' -> case passwordFromAuthUser u' of
      Nothing  -> error "Nem lett jelszó megadva!"
      Just pwd -> P.runPersist $ P.saveUser persist user
  return ()

createAdminUser :: P.Persist -> FilePath -> UserRegInfo -> IO ()
createAdminUser persist usersdb = userRegInfoCata $
  \name password email fullName timeZone ->
    let usr = User {
        u_role = Admin
      , u_username = Username name
      , u_email = Email email
      , u_name = fullName
      , u_timezone = timeZone
      , u_language = Language "hu" -- TODO: I18N
      }
    in createUser persist usersdb usr password

-- * User registration handler

data RegError
  = RegError LogLevel String
  | RegErrorUserExist Username

instance Error RegError where
  noMsg      = RegError DEBUG ""
  strMsg msg = RegError DEBUG msg

readParameter :: (MonadSnap m) => Parameter a -> m (Maybe a)
readParameter param = do
  reqParam <- getParam . B.pack . name $ param
  return (reqParam >>= decode param . T.unpack . decodeUtf8)

registrationTitle :: Translation String
registrationTitle = Msg_Registration_Title "Registration"

{-
User registration request
- On GET request it renders the HTML registration form with
  username, email address, and full name input fields, that
  has the proper JavaScript validation method.
- On POST request it validates the input fields.
  It the input field values are incorrect renders the error page, otherwise
  runs the User story to create a UserRegistration
  data in the persistence layer, after send the information via email
-}
registrationRequest :: Config -> Handler App App ()
registrationRequest config = method GET renderForm <|> method POST saveUserRegData where

  -- Creates a timeout days later than the given time
  timeout :: Integer -> UTCTime -> UTCTime
  timeout days = addUTCTime (fromInteger (60 * 60 * 24 * days))

  createUserRegData :: Username -> Email -> String -> IO UserRegistration
  createUserRegData user email name = do
    now <- getCurrentTime
    -- TODO random token
    return $ UserRegistration {
      reg_username = usernameCata id user
    , reg_email    = emailFold    id email
    , reg_name     = name
    , reg_token    = "token"
    , reg_timeout  = timeout 2 now
    }

  renderForm = renderPublicPage . dynamicTitleAndHead registrationTitle $ do
    msg <- getI18N
    return $ do
      postForm "/reg_request" ! (A.id . formId $ regForm) $ do
        table (fieldName registrationTable) (fieldName registrationTable) $ do
          tableLine (msg $ Msg_Registration_Username "Username:") $ textInput (name regUsernamePrm) 20 Nothing ! A.required ""
          tableLine (msg $ Msg_Registration_Email "Email:") $ textInput (name regEmailPrm) 20 Nothing ! A.required ""
          tableLine (msg $ Msg_Registration_FullName "Full name:") $ textInput (name regFullNamePrm) 20 Nothing ! A.required ""
        submitButton (fieldName regSubmitBtn) (msg $ Msg_Registration_SubmitButton "Registration")
      linkToRoute (msg $ Msg_Registration_GoBackToLogin "Back to login")


  saveUserRegData = do
    u <- readParameter regUsernamePrm
    e <- readParameter regEmailPrm
    f <- readParameter regFullNamePrm

    renderPage $ do
      i18n <- lift i18nH
      case (u,e,f) of
        (Nothing, _, _) -> throwError . strMsg $ i18n $
          Msg_Registration_InvalidUsername "Invalid username"
        (Just username, Just email, Just fullname) -> do
            exist <- lift $ registrationStory (S.doesUserExist username)
            when (isLeft exist) . throwError . strMsg . i18n $
              Msg_Registration_HasNoUserAccess "No access allowed to the user's data."
            when (fromRight exist) . throwError . strMsg . i18n $
              Msg_Registration_UserAlreadyExists "User already exists."
            userRegData <- liftIO $ createUserRegData username email fullname
            result <- lift $ registrationStory (S.createUserReg userRegData)
            when (isLeft result) . throwError . strMsg . i18n $
              Msg_Registration_RegistrationNotSaved "The registration has not been saved."
            lang <- lift $ withTop sessionManager languageFromSession
            let language = maybe (Language "en") id lang
            let key = fromRight result
            lift $ withTop sendEmailContext $
              sendEmail
                email
                (i18n $ Msg_Registration_EmailSubject "BE-AD: Registration")
                (i18n $ Msg_Registration_EmailBody registrationEmailTemplate)
                RegTemplate {
                    regUsername = reg_username userRegData
                  , regUrl = createUserRegAddress key language userRegData
                  }
            lift $ pageContent
        _ -> throwError . strMsg . i18n $
               Msg_Registration_RequestParameterIsMissing "Some request parameter is missing."

  createUserRegAddress :: UserRegKey -> Language -> UserRegistration -> String
  createUserRegAddress key (Language language) reg =
    -- TODO: Add the correct address of the server
    requestRoute (join [emailHostname config, "/reg_final"])
                 [ requestParameter regUserRegKeyPrm key
                 , requestParameter regTokenPrm      (reg_token reg)
                 , requestParameter regUsernamePrm   (Username . reg_username $ reg)
                 , requestParameter regLanguagePrm   language
                 ]

  -- Calculates the result of an (ErrorT String ...) transformator and
  -- returns the (Right x) or renders the error page with the given error
  -- message in (Left x)
  renderPage m = do
    x <- runErrorT m
    either registrationErrorPage return x

{-
Registration finalization
- On GET request: The user gets and email from the BE-AD this email contains
  the necessary code and token in for to finalize the registration
  The system reads the UserREgistration data and decides that the registration
  can go on, this depends on the factor, the first, that the user is not registered yet
  and the registration time limit has not passed yet.
  If the registration is not permitted the system renders the error page, otherwise
  a page where the user can enter the desired password. The password field is validated
  by JavaScript.
- On POST request the desired password is validated by server side too, if the validation
  is passed than the user registration happens. If any error occurs during the registration
  an error page is shown, otherwise the page is redirected to "/"
-}
finalizeRegistration :: Handler App App ()
finalizeRegistration = method GET renderForm <|> method POST createStudent where

  readRegParameters = do
    username <- readParameter regUsernamePrm
    key      <- readParameter regUserRegKeyPrm
    token    <- readParameter regTokenPrm
    language <- readParameter regLanguagePrm
    case (key, token, username, language) of
      (Just k, Just t, Just u, Just l) -> return $ Just (k,t,u,l)
      _                                -> return $ Nothing

  renderForm = do
    values <- readRegParameters
    i18n <- i18nH
    case values of
      Nothing -> registrationErrorPage $ i18n $
        Msg_RegistrationFinalize_NoRegistrationParametersAreFound "No registration parameters found."
      Just (key, token, username, language) -> do
        result <- registrationStory $ do
                    userReg   <- S.loadUserReg key
                    existence <- S.doesUserExist username
                    return (userReg, existence)
        case result of
          Left e -> registrationErrorPage $
            printf (i18n $ Msg_Registration_GenericError "Some error happened: %s") (show e)
          Right (userRegData,exist) -> do
            -- TODO: Check username and token values
            now <- liftIO $ getCurrentTime
            case (reg_timeout userRegData < now, exist) of
              (True , _) -> errorPageWithTitle
                (Msg_Registration_Title "Registration")
                (i18n $ Msg_RegistrationFinalize_InvalidToken "The registration token has expired, start the registration over.")
              (False, True) -> errorPageWithTitle
                (Msg_Registration_Title "Registration")
                (i18n $ Msg_RegistrationFinalize_UserAlreadyExist "This user already exists.")
              (False, False) -> renderPublicPage . dynamicTitleAndHead registrationTitle $ do
                return $ do
                  postForm "reg_final" ! (A.id . formId $ regFinalForm) $ do
                    table (fieldName registrationTable) (fieldName registrationTable) $ do
                      tableLine (i18n $ Msg_RegistrationFinalize_Password "Password:") $ passwordInput (name regPasswordPrm) 20 Nothing ! A.required ""
                      tableLine (i18n $ Msg_RegistrationFinalize_PwdAgain "Password (again):") $ passwordInput (name regPasswordAgainPrm) 20 Nothing ! A.required ""
                      tableLine (i18n $ Msg_RegistrationFinalize_Timezone "Time zone:") $ defEnumSelection (name regTimeZonePrm) UTC ! A.required ""
                    hiddenParam regUserRegKeyPrm key
                    hiddenParam regTokenPrm      token
                    hiddenParam regUsernamePrm   username
                    hiddenParam regLanguagePrm   language
                    H.br
                    submitButton (fieldName regSubmitBtn) (i18n $ Msg_RegistrationFinalize_SubmitButton "Register")
                  H.br
                  linkToRoute (i18n $ Msg_RegistrationFinalize_GoBackToLogin "Back to login")

  hiddenParam parameter value = hiddenInput (name parameter) (encode parameter value)

  createStudent = do
    values <- readRegParameters
    pwd    <- readParameter regPasswordPrm
    tz     <- readParameter regTimeZonePrm
    msg <- i18nH
    case (values, pwd, tz) of
      (Nothing,_,_) -> errorPageWithTitle (Msg_Registration_Title "Registration") $ msg $
        Msg_RegistrationCreateStudent_NoParameters "No registration parameters."
      (Just (key, token, username, language), Just password, Just timezone) -> do
        result <- registrationStory (S.loadUserReg key)
        case result of
          Left e -> errorPageWithTitle (Msg_Registration_Title "Registration") $ msg $
            Msg_RegistrationCreateStudent_InternalError "Some internal error happened."
          Right userRegData -> do
            now <- liftIO getCurrentTime
            -- TODO: Check username and token values (are the same as in the persistence)
            case (reg_timeout userRegData < now) of
              True -> errorPageWithTitle (Msg_Registration_Title "Registration") $ msg $
                Msg_RegistrationCreateStudent_InvalidToken "The registration token has expired, start the registration over."
              False -> do
                result <- withTop auth $ createNewUser userRegData password timezone (Language language)
                redirect "/"

  log lvl msg = withTop serviceContext $ logMessage lvl msg


createNewUser :: UserRegistration -> String -> TimeZone -> Language -> Handler App (AuthManager App) (Either RegError ())
createNewUser reg password timezone language = runErrorT $ do
  -- Check if the user is exist already
  userExistence <- checkFailure =<< lift (registrationStory (S.doesUserExist username))
  when userExistence . throwError $ (RegErrorUserExist username)

  -- Registers the user in the Snap authentication module
  lift $ registerUser (B.pack $ name regUsernamePrm) (B.pack $ name regPasswordPrm)
  let user = User {
      u_role = Student
    , u_username = username
    , u_email = email
    , u_name = fullname
    , u_timezone = timezone
    , u_language = language
    }

  -- Check if the Snap Auth registration went fine
  createdUser <- lift $ withBackend $ \r -> liftIO $ lookupByLogin r (usernameCata T.pack username)
  when (isNothing createdUser) . throwError . RegError ERROR $ "User was not created in the Snap Auth module"
  let snapAuthUser = fromJust createdUser
  when (isNothing . passwordFromAuthUser $ snapAuthUser) . throwError . RegError ERROR $ "Snap Auth: no password is created"
  let snapAuthPwd = fromJust . passwordFromAuthUser $ snapAuthUser

  -- Creates the user in the persistence layer
  checkFailure =<< lift (registrationStory (S.createUser user))
  return ()

  where
    username = Username . reg_username $ reg
    email    = Email . reg_email $ reg
    fullname = reg_name reg

    -- Checks if the result of a story is failure, in the case of failure
    -- it throws an exception, otherwise lift's the result into the monadic
    -- calculation
    checkFailure (Left _)  = throwError . RegError ERROR $ "User story failed"

    checkFailure (Right x) = return x

pageContent :: Handler App a ()
pageContent = renderPublicPage . dynamicTitleAndHead (Msg_Registration_Title "Registration") $ do
  msg <- getI18N
  return $ do
    H.p . fromString . msg $ Msg_RegistrationTokenSend_Title "The registration token has been sent in email, it shall arrive soon."
    H.br
    linkToRoute (msg $ Msg_RegistrationTokenSend_GoBackToLogin "Back to login")

registrationErrorPage = errorPageWithTitle registrationTitle

-- * Tools

-- Returns true if the given value is Left x, otherwise false
isLeft :: Either a b -> Bool
isLeft (Left _)  = True
isLeft (Right _) = False

-- Return the value from Right x otherwise throws a runtime error
fromRight :: Either a b -> b
fromRight (Right x) = x
fromRight (Left _)  = error "fromRight: left found"


-- * Email template

registrationEmailTemplate :: String
registrationEmailTemplate = unlines
  [ "Dear future user,"
  , ""
  , "This email was sent to you, because somebody has tried register to our BE-AD"
  , "service with your email address as \"{{regUsername}}\".  Please confirm this"
  , "intention by following the link below:"
  , ""
  , "{{regUrl}}"
  , ""
  , "Thanks,"
  , "The administrators"
  , ""
  , "PS: If you received this email by accident, or you do not want to register"
  , "    any more, feel free to ignore this message."
  ]
