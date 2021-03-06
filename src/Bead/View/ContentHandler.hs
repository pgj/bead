{-# LANGUAGE OverloadedStrings  #-}
module Bead.View.ContentHandler (
    logMessage
  , withUserState
  , runStory
  , userStory
  , registrationStory
  , getParameter
  , getParameterValues -- Calculates a list of values for the given parameter
  , getParameterOrError
  , getOptionalParameter -- Calculates the value of the given parameter if it is defined
  , getOptionalOrNonEmptyParameter
  , getJSONParam
  , getJSONParameters -- Calculates the json encoded parameter values into a list
  , getDictionaryInfos -- Calculates a list of language and dictionaryInfo
  , i18nE
  , i18nH
  , blazeI18n
  , renderBootstrapPage
  , renderBootstrapPublicPage
  , renderPublicPage
  , setInSessionE
  , setReqParamInSession
  , sessionToken
  , userState
  , userTimeZone
  , userTimeZoneToLocalTimeConverter
  , userTimeZoneToUTCTimeConverter
  , foundTimeZones
  , logout
  , ContentHandler
  , ContentError
  , contentError
  , UserTimeConverter
  , contentHandlerError
  , contentHandlerErrorMap
  , contentHandlerErrorMsg
  , module Bead.Controller.Logging
  , module Control.Monad.Error
  ) where

import           Control.Applicative
import           Control.Monad.Error
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString.UTF8  as BU
import qualified Data.Map as Map (lookup)
import           Data.Maybe (isNothing, fromJust)
import           Data.String (IsString(..))
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import           Data.Time (UTCTime, LocalTime)
import qualified Data.Time as Time

import           Snap hiding (get)
import           Snap.Blaze (blaze)
import           Snap.Snaplet.Auth hiding (logout)
import qualified Snap.Snaplet.Auth as A (logout)
import           Snap.Snaplet.Session
import           Snap.Util.FileUploads
import           Text.Blaze.Html5 (Html)

import           Bead.Config
import           Bead.Controller.Logging as L
import           Bead.Controller.Logging
import           Bead.Controller.ServiceContext hiding (serviceContext, name)
import qualified Bead.Controller.UserStories as S
import           Bead.Daemon.Logout
import           Bead.Domain.Entities (TimeZoneName)
import           Bead.Domain.TimeZone
import           Bead.View.BeadContext
import           Bead.View.DataBridge
import           Bead.View.Dictionary
import           Bead.View.I18N (IHtml, translate)
import           Bead.View.Pagelets (runBootstrapPage, bootstrapUserFrame)
import           Bead.View.RouteOf (ReqParam(..))
import           Bead.View.Session
import           Bead.View.Translation

import           Bead.View.Fay.JSON.ServerSide

newtype ContentError = ContentError (Maybe String)
  deriving (Show)

contentError
  nothing
  msg
  c = case c of
    (ContentError Nothing)    -> nothing
    (ContentError (Just msg)) -> msg

instance Error ContentError where
  noMsg  = ContentError Nothing
  strMsg = ContentError . Just

contentHandlerError :: String -> ContentError
contentHandlerError = ContentError . Just

contentHandlerErrorMap :: (Maybe String -> a) -> ContentError -> a
contentHandlerErrorMap f (ContentError x) = f x

contentHandlerErrorMsg = contentHandlerErrorMap (maybe "Unknown message" id)

type ContentHandler' b c = ErrorT ContentError (BeadHandler' b) c

-- ContentHandler is a handler for render Bead pages or information to the client
-- also equiped with error handling, mainly used for render inner pages.
type ContentHandler c = ContentHandler' BeadContext c

-- | The 'logMessage' logs a message at a given level using the service context logger
logMessage :: LogLevel -> String -> BeadHandler' b ()
logMessage lvl msg = do
  context <- getServiceContext
  liftIO $ L.log (logger context) lvl msg

sessionToken :: BeadHandler' b String
sessionToken = T.unpack <$> csrfTokenTop

userState :: ContentHandler UserState
userState = do
  context   <- lift $ getServiceContext
  mUsername <- lift $ usernameFromSession
  token     <- lift $ sessionToken
  case mUsername of
    Nothing -> do
      lift $ logMessage ERROR "User is not logged in the session"
      throwError . strMsg $ "User is not logged in the session"
    Just user -> do
      let users = userContainer context
      userData <- liftIO $ users `userData` (userToken (user, token))
      case userData of
        Nothing -> do
          lift $ logMessage ERROR "No data found for the user"
          throwError . strMsg $ "No data found for the user"
        Just ud -> return ud

-- Produces a handler that returns the user's actual time zone
userTimeZone :: ContentHandler TimeZoneName
userTimeZone = timezone <$> userState

-- Represents a functions that converts a given UTC time into
-- the user's timezone
type UserTimeConverter = UTCTime -> LocalTime

withUserTimeZoneContext :: (TimeZoneConverter -> TimeZoneName -> a) -> ContentHandler a
withUserTimeZoneContext f = do
  zi  <- userTimeZone
  tzc <- lift getTimeZoneConverter
  return (f tzc zi)

-- Produces the a UserTimeZoneConverter function for the user's time zone
userTimeZoneToLocalTimeConverter :: ContentHandler UserTimeConverter
userTimeZoneToLocalTimeConverter = withUserTimeZoneContext zoneInfoToLocalTimeSafe

-- Produces a function that convert a given local time into a UTC time using
-- the user's actual time zone
userTimeZoneToUTCTimeConverter :: ContentHandler (LocalTime -> UTCTime)
userTimeZoneToUTCTimeConverter = withUserTimeZoneContext zoneInfoToUTCTimeSafe

-- Produces a list of the found time zones
foundTimeZones :: BeadHandler' b [TimeZoneName]
foundTimeZones = zoneInfos <$> getTimeZoneConverter

i18nE :: (IsString s) => ContentHandler (Translation String -> s)
i18nE = do
  lang <- lift languageFromSession
  when (isNothing lang) . throwError . strMsg $ "Language was not defined in session"
  -- If the dictionary is not found for the language stored in session
  -- the identical dictionary is returned. The fromString is necessary
  -- for the Attribute names and values used in html templating engines
  d <- lift . getDictionary . fromJust $ lang
  return (fromString . (unDictionary $ maybe idDictionary id d)) -- TODO: I18N

i18nH :: BeadHandler' a (Translation String -> String)
i18nH = do
  language <- languageFromSession
  t <- maybe (return Nothing) getDictionary language
  return $ maybe trans unDictionary t

blazeI18n :: (I18N -> Html) -> ContentHandler ()
blazeI18n h = i18nE >>= blaze . h

-- Renders a Page from the given IHtml function which
-- needs the session timeout seconds
renderBootstrapPage :: IHtml -> ContentHandler ()
renderBootstrapPage page = do
  state <- userState
  secs <- fmap sessionTimeout $ lift getConfiguration
  i18nE >>= blaze . (runBootstrapPage (bootstrapUserFrame state page secs))

-- Renders the public page selecting the I18N translation based on the
-- language stored in the session, if there is no such value, the
-- default translator function is used
renderPublicPage :: IHtml -> BeadHandler' b ()
renderPublicPage p = do
  language <- languageFromSession
  t <- maybe (return Nothing) getDictionary language
  let translator = maybe trans unDictionary t
  blaze $ translate translator p

-- Renders the public page selecting the I18N translation based on the
-- language stored in the session, if there is no such value, the
-- default translator function is used
renderBootstrapPublicPage :: IHtml -> BeadHandler' b ()
renderBootstrapPublicPage p = do
  language <- languageFromSession
  t <- maybe (return Nothing) getDictionary language
  let translator = maybe trans unDictionary t
  blaze (runBootstrapPage p translator)

withUserState :: (UserState -> ContentHandler c) -> ContentHandler c
withUserState = (userState >>=)

getParameterOrError :: Parameter a -> BeadHandler' b (Either String a)
getParameterOrError param
  = either (Left . contentHandlerErrorMsg) (Right . id)
     <$> (runErrorT $ getParameter param)

-- Tries to decode the given value with the parameter description, if
-- fails throws an error, otherwise returns the value
decodeParamValue :: Parameter a -> BU.ByteString -> ContentHandler' b a
decodeParamValue param value = do
  let v = T.unpack $ TE.decodeUtf8 value
      decoded = decode param v
  maybe
    (throwError . strMsg . decodeError param $ v)
    return
    decoded

getParameter :: Parameter a -> ContentHandler' b a
getParameter param = do
  reqParam <- getParam . B.pack . name $ param
  maybe
    (throwError . strMsg $ notFound param) -- TODO: I18N
    (decodeParamValue param)
    reqParam

-- Calculates a list of values named and decoded by the given parameter
-- If the parameter is not found throws an error, if one of the parameter
-- values are not decodable throws an error otherwise
-- returns a list of the decoded values
getParameterValues :: Parameter a -> ContentHandler' b [a]
getParameterValues param = do
  params <- getParams
  let paramName = name param
  maybe
    (throwError . strMsg $ notFound param) -- TODO: I18N
    (mapM (decodeParamValue param))
    (Map.lookup (fromString paramName) params)

-- Calculates a Just value named and decoded by the given paramater,
-- supposing that the parameter are optional, if it not presented
-- calculates Nothing, if decoding fails, throws an Error
getOptionalParameter :: Parameter a -> ContentHandler' b (Maybe a)
getOptionalParameter param = do
  params <- getParams
  let paramName = name param
  case Map.lookup (fromString paramName) params of
    Nothing  -> return Nothing
    Just []  -> throwError . strMsg $ concat [paramName, " contains zero values."] -- TODO: I18N
    Just [x] -> Just <$> decodeParamValue param x
    Just (_:_) -> throwError . strMsg $ concat [paramName, " has more than one value."] -- TODO: I18N

-- Calculates a Just value named and decoded by the given paramater,
-- supposing that the parameter are optional, if it not presented
-- calculates Nothing, if decoding fails, throws an Error
getOptionalOrNonEmptyParameter :: Parameter a -> ContentHandler' b (Maybe a)
getOptionalOrNonEmptyParameter param = do
  params <- getParams
  let paramName = name param
  case Map.lookup (fromString paramName) params of
    Nothing  -> return Nothing
    Just []  -> throwError . strMsg $ concat [paramName, " contains zero values."] -- TODO: I18N
    Just [x] -> case B.null x of
                  True  -> return Nothing
                  False -> Just <$> decodeParamValue param x
    Just (_:_) -> throwError . strMsg $ concat [paramName, " has more than one value."] -- TODO: I18N


getJSONParam :: (Data a) => String -> String -> ContentHandler a
getJSONParam param msg = do
  x <- getParam . B.pack $ param
  case x of
    Nothing -> throwError . strMsg $ msg
    Just y  -> case decodeFromFay . B.unpack $ y of
      Nothing -> throwError . strMsg $ "Decoding error"
      Just z  -> return z

-- Decode multiple values for the given parameter names.
-- This approach can be used for checkbox contained values.
-- If no parameter is found in the request, an empty list is returned.
getJSONParameters :: (Data a, Show a) => String -> String -> ContentHandler [a]
getJSONParameters param msg = do
  params <- getParams
  case Map.lookup (fromString param) params of
    Nothing -> return []
    Just [] -> return []
    Just vs -> mapM decodePrm vs
  where
    decodePrm v =
      let v' = B.unpack v
      in case decodeFromFay v' of
           Nothing -> throwError . strMsg $ concat ["Decoding error:", v', " ", msg]
           Just  x -> return x

-- Computes a list that contains language and dictionary info pairs
getDictionaryInfos :: ContentHandler DictionaryInfos
getDictionaryInfos = lift dcGetDictionaryInfos

setReqParamInSession :: ReqParam -> ContentHandler ()
setReqParamInSession (ReqParam (k,v)) = setInSessionE k v

setInSessionE :: String -> String -> ContentHandler ()
setInSessionE k v
  = lift $ setInSessionTop (T.pack k) (T.pack v)

-- Runs a user story within a service context where the user is logged in
-- and throws a handler error if the story has failed
-- otherwise returns the computed value
userStory :: S.UserStory a -> ContentHandler a
userStory story = do
  i18n <- lift i18nH
  x <- lift . runStory $ story
  case x of
    Left e  -> throwError . strMsg . S.translateUserError i18n $ e
    Right y -> return y

-- Runs a UserStory in the registration context
registrationStory :: S.UserStory a -> BeadHandler' b (Either S.UserError a)
registrationStory s = getServiceContext >>=
  \context -> do i18n <- i18nH; liftIO $ (forgetUserState <$> S.runUserStory context i18n Registration s)
  where
    forgetUserState = either Left (Right . fst)

-- | Runs a user story for authenticated user and saves the new user state
--   into the service context
runStory :: S.UserStory a -> BeadHandler' b (Either S.UserError a)
runStory story = do
  result <- serviceContextAndUserData $ \context logoutDaemon users authUser -> do
      let unameFromAuth = usernameFromAuthUser authUser
      token  <- sessionToken
      let usrToken = userToken (unameFromAuth, token)
      ustate <- liftIO $ userData users usrToken
      case ustate of
        Nothing -> return . Left . strMsg $ "The user is timed out: " ++ show unameFromAuth
        Just state -> do
          liftIO $ do
            now <- Time.getCurrentTime
            userActivity logoutDaemon usrToken now
          i18n <- i18nH
          eResult <- liftIO $ S.runUserStory context i18n state story
          case eResult of
            Left e -> return . Left $ e
            Right (a,state') -> do
              liftIO $ modifyUserData users usrToken (const state')
              refreshSession
              return $ Right a
  case result of
    Left msg -> return . Left . strMsg . show $ msg
    Right x -> return x

  where
    refreshSession = do
      commitSessionTop
      touchSessionTop

    serviceContextAndUserData
      :: (ServiceContext -> LogoutDaemon -> UserContainer UserState -> AuthUser -> BeadHandler' b a)
      -> BeadHandler' b (Either String a)
    serviceContextAndUserData f = do
      (context, logoutDaemon) <- getServiceContextAndLogoutDaemon
      let users = userContainer context
      um <- currentUserTop
      case um of
        Nothing -> return . Left $ "Unauthenticated user"
        Just authUser -> liftM Right $ f context logoutDaemon users authUser

logout :: BeadHandler' b ()
logout = do
  debugMessage "Logout is called!"
  um <- currentUserTop
  case um of
    Nothing -> do
      logMessage ERROR "There is no user logged in to log out."
      resetPrivateSessionData

    Just authUser -> do
      let unameFromAuth = usernameFromAuthUser authUser
      (context, logoutDaemon) <- getServiceContextAndLogoutDaemon
      let users = userContainer context
      token <- sessionToken
      liftIO $ do
        let usrToken = userToken (unameFromAuth, token)
        users `userLogsOut` usrToken
        userLogout logoutDaemon usrToken
      resetPrivateSessionData
      logoutTop
