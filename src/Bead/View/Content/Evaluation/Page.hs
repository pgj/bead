{-# LANGUAGE OverloadedStrings #-}
module Bead.View.Content.Evaluation.Page (
    evaluation
  , modifyEvaluation
  ) where

import           Control.Monad.IO.Class
import           Control.Monad
import           Control.Arrow ((&&&))
import           Data.Maybe (fromMaybe)
import           Data.Monoid
import           Data.String (fromString)
import           Data.Time (getCurrentTime)

import qualified Bead.Controller.Pages as Pages
import           Bead.Controller.UserStories (submissionDescription)
import           Bead.Domain.Entity.Assignment as Assignment
import           Bead.Domain.Evaluation
import           Bead.View.Content as C
import           Bead.View.Content.Bootstrap as Bootstrap
import           Bead.View.Content.Comments
import           Bead.View.Content.SeeMore

import           Text.Blaze.Html5 as H
import           Text.Blaze.Html5.Attributes as A

evaluation :: ViewModifyHandler
evaluation = ViewModifyHandler evaluationPage evaluationPostHandler

modifyEvaluation :: ViewModifyHandler
modifyEvaluation = ViewModifyHandler modifyEvaluationPage modifyEvaluationPost

-- Page Data consitits of a description for a submission key, which contains
-- the assignment key as well, the submission key, an evautation key, and
-- the time converter for the actual user.
-- If the evaluation key is Nothing means a new evaulation, otherwise
-- the modification of a given evaulation is done
data PageData = PageData {
    sbmDesc :: SubmissionDesc
  , sbmSubmissionKey :: SubmissionKey
  , sbmEvaluationKey :: Maybe EvaluationKey
  , userTime :: UserTimeConverter
  }

evaluationPage :: GETContentHandler
evaluationPage = do
  sk <- getParameter submissionKeyPrm
  sd <- userStory (submissionDescription sk)
  tc <- userTimeZoneToLocalTimeConverter
  let pageData = PageData {
      sbmDesc = sd
    , sbmSubmissionKey = sk
    , sbmEvaluationKey = Nothing
    , userTime = tc
    }
  return $ evaluationContent pageData

modifyEvaluationPage :: GETContentHandler
modifyEvaluationPage = do
  sk <- getParameter submissionKeyPrm
  ek <- getParameter evaluationKeyPrm
  sd <- userStory (submissionDescription sk)
  tc <- userTimeZoneToLocalTimeConverter
  let pageData = PageData {
    sbmDesc = sd
  , sbmSubmissionKey = sk
  , sbmEvaluationKey = Just ek
  , userTime = tc
  }
  return $ evaluationContent pageData

-- Reads the evaluation result, from the parameters and determine if the content
-- of the text area would be a comment of the textual evaluation of the given submission.
-- The result of the computation is a UserActon which is a CreateComment or
-- something that depends on the key end the evaluation itself.
abstractEvaluationPostHandler
  :: ContentHandler key
  -> (key -> C.Evaluation -> UserAction)
  -> POSTContentHandler
abstractEvaluationPostHandler getEvKeyParameter evCommand = do
  sk <- getParameter submissionKeyPrm
  commentText <- getParameter evaluationValuePrm
  commentOrResult <- getJSONParam (fieldName evaluationResultField) "There can be no evaluation found."
  withEvalOrComment commentOrResult
    (do (mrole,mname) <- (getRole &&& getName) <$> userState
        let uname = fromMaybe "???" mname
        case mrole of
          Nothing -> return $ LogMessage "The user is not logged in" -- Impossible
          Just role -> do
            now <- liftIO $ getCurrentTime
            return $ SubmissionComment sk Comment {
               comment = commentText
             , commentAuthor = uname
             , commentDate = now
             , commentType = roleToCommentType role
             })
    (\result -> do
        key <- getEvKeyParameter
        let e = C.Evaluation {
            evaluationResult = result
          , writtenEvaluation = commentText
          }
        return $ evCommand key e)
  where
    roleToCommentType = roleCata
      CT_Student
      CT_GroupAdmin
      CT_CourseAdmin
      CT_Admin

    getRole = userStateCata
      Nothing
      Nothing
      Nothing
      (\_username _uid _page _name role _token _timezone _status -> Just role)

    getName = userStateCata
      Nothing
      Nothing
      Nothing
      (\_username _uid _page name _role _token _timezone _status -> Just name)

evaluationPostHandler :: POSTContentHandler
evaluationPostHandler = abstractEvaluationPostHandler (getParameter submissionKeyPrm) NewEvaluation

modifyEvaluationPost :: POSTContentHandler
modifyEvaluationPost = abstractEvaluationPostHandler (getParameter evaluationKeyPrm) ModifyEvaluation

inputEvalResult :: EvConfig -> IHtml

inputEvalResult (EvConfig (BinEval _cfg)) = do
  msg <- getI18N
  return $ Bootstrap.radioButtonGroup (fieldName evaluationResultField) $
    [ (True,  encodeToFay' "inputEvalResult" EvCmtComment,  msg $ msg_Evaluation_New_Comment "New Comment")
    , (False, encodeToFay' "inputEvalResult" $ binary Passed, msg $ msg_Evaluation_Accepted "Accepted")
    , (False, encodeToFay' "inputEvalResult" $ binary Failed, msg $ msg_Evaluation_Rejected "Rejected")
    ]
  where
    binary = EvCmtResult . binaryResult

-- When the page is dynamic the percentage spinner is hooked on the field
inputEvalResult (EvConfig (PctEval _cfg)) =
  return $ hiddenInput
    (fieldName evaluationResultField)
    (fromString . errorOnNothing . encodeToFay $ percentageResult 0.0)

errorOnNothing = maybe (error "Invalid input encoding.") Prelude.id

-- * View

evaluationContent :: PageData -> IHtml
evaluationContent pd = do
  let sd = sbmDesc pd
      tc = userTime pd
  msg <- getI18N
  return $ do
    Bootstrap.row $ Bootstrap.colMd12 $
      H.p $ fromString . msg $ msg_Evaluation_Info $ concat
        [ "It is not mandatory to evaluate the submission, it is allowed to comment on it only.  "
        , "The student may answer the comments by further comments.  The submission may be "
        , "evaluated many times."
        ]

    Bootstrap.row $ Bootstrap.colMd12 $ Bootstrap.table $
      H.tbody $ do
        tr $ do
            td $ fromString $ msg $ msg_Evaluation_Course "Course: "
            td $ fromString $ eCourse sd
        maybe
          mempty
          (\group -> tr $ do
             td $ fromString $ msg $ msg_Evaluation_Group "Group: "
             td $ fromString group)
          (eGroup sd)
        tr $ do
            td $ fromString $ msg $ msg_Evaluation_Student "Student: "
            td $ fromString $ eStudent sd
        tr $ do
            td $ fromString $ msg $ msg_Evaluation_Username "Username: "
            td $ fromString $ uid Prelude.id $ eUid sd
        tr $ do
            td $ fromString $ msg $ msg_Evaluation_SubmissionDate "Date of submission: "
            td $ fromString $ showDate . tc $ eSubmissionDate sd

    Bootstrap.row $ Bootstrap.colMd12 $ do
      let downloadSubmissionButton =
            Bootstrap.buttonLink
              (routeOf $ Pages.getSubmission submissionKey ())
              (msg $ msg_Evaluation_Submitted_Solution_Zip_Link "Download")

      h2 $ fromString $ msg $ msg_Evaluation_Submitted_Solution "Submission"
      if (Assignment.isZippedSubmissions . Assignment.aspects . eAssignment $ sd)
        then do
          H.p $ fromString . msg $ msg_Evaluation_Submitted_Solution_Zip_Info $ mconcat
            [ "The submission was uploaded as a compressed file so it could not be displayed verbatim.  "
            , "But it may be downloaded as a file by clicking on the link."
            ]
          downloadSubmissionButton
        else do
          H.p $ fromString . msg $ msg_Evaluation_Submitted_Solution_Text_Info $
            "The submission may be downloaded as a plain text file by clicking on the link."
          downloadSubmissionButton
          H.br
          H.div # submissionTextDiv $ seeMorePre msg maxLength maxLines (eSolution sd)

    Bootstrap.row $ Bootstrap.colMd12 $
      postForm (routeOf . evPage $ maybeEvalKey) $ do
        Bootstrap.optionalTextArea (fieldName evaluationValueField) "" $ mempty
        hiddenInput (fieldName assignmentKeyField) (paramValue $ eAssignmentKey sd)
        hiddenInput (fieldName evCommentOnlyText) (msg $ msg_Evaluation_New_Comment "New Comment")
        Bootstrap.formGroup . evaluationDiv . i18n msg . inputEvalResult . Assignment.evType $ eAssignment sd
        Bootstrap.submitButton
          (fieldName saveEvalBtn) (fromString . msg $ msg_Evaluation_SaveButton "Submit")

    let comments = submissionDescToCFs sd
    when (not $ null comments) $ do
      Bootstrap.row $ Bootstrap.colMd12 $ hr
      Bootstrap.row $ Bootstrap.colMd12 $
        H.h2 (fromString . msg $ msg_Comments_Title "Comments")
      -- Renders the comment area where the user can place a comment
      Bootstrap.row $ Bootstrap.colMd12 $ hr
      i18n msg $ commentsDiv tc comments

  where
    evaluationDiv = withEvaluationData
      (evConfig . Assignment.evType . eAssignment $ sbmDesc pd)
      (const H.div)
      (const $ H.div ! A.id (fieldName evaluationPercentageDiv))

    submissionKey = sbmSubmissionKey pd
    maybeEvalKey  = sbmEvaluationKey pd

    evPage (Just ek) = Pages.modifyEvaluation submissionKey ek ()
    evPage Nothing   = Pages.evaluation submissionKey ()

    maxLength = 100
    maxLines  = 5

