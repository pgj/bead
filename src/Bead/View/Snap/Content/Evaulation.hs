{-# LANGUAGE OverloadedStrings #-}
module Bead.View.Snap.Content.Evaulation (
    evaulation
  , modifyEvaulation
  ) where

import Data.String (fromString)
import Control.Monad (liftM)

import Bead.Domain.Types (readMsg)
import Bead.Domain.Shared
import Bead.Domain.Relationships (SubmissionDesc(..))
import Bead.Controller.Pages as P(Page(Evaulation, ModifyEvaulation))
import Bead.Controller.ServiceContext (UserState(..))
import Bead.Controller.UserStories (submissionDescription)
import Bead.View.Snap.Pagelets
import Bead.View.Snap.Content as C
import Bead.View.Snap.Content.Comments

import Bead.Domain.Evaulation

import Text.Blaze.Html5 (Html)
import qualified Text.Blaze.Html5 as H

evaulation :: Content
evaulation = getPostContentHandler evaulationPage evaulationPostHandler

modifyEvaulation :: Content
modifyEvaulation = getPostContentHandler modifyEvaulationPage modifyEvaulationPost

data PageData = PageData {
    sbmDesc :: SubmissionDesc
  , sbmKey  :: Either EvaulationKey SubmissionKey
  }

evaulationPage :: GETContentHandler
evaulationPage = withUserStateE $ \s -> do
  sk <- getParamE (fieldName submissionKeyField) SubmissionKey "Submission key does not found"
  sd <- runStoryE (submissionDescription sk)
  let pageData = PageData {
      sbmKey  = Right sk
    , sbmDesc = sd
    }
  renderPagelet $ withUserFrame s (evaulationContent pageData)

modifyEvaulationPage :: GETContentHandler
modifyEvaulationPage = withUserStateE $ \s -> do
  sk <- getParamE (fieldName submissionKeyField) SubmissionKey "Submission key does not found"
  ek <- getParamE (fieldName evaulationKeyField) EvaulationKey "Evaulation kes does not found"
  sd <- runStoryE (submissionDescription sk)
  let pageData = PageData {
    sbmKey  = Left ek
  , sbmDesc = sd
  }
  renderPagelet $ withUserFrame s (evaulationContent pageData)

evaulationPostHandler :: POSTContentHandler
evaulationPostHandler = do
  sk <- getParamE (fieldName submissionKeyField) SubmissionKey "Submission key does not found"
  ev <- getParamE (fieldName evaulationValueField) id "Evaulation value does not found"
  er <- getParamE (fieldName evaulationResultField)
                   (readMsg "Evaulation result")
                   "Evaulation result does not found"
  let e = C.Evaulation {
    evaulationResult = er
  , writtenEvaulation = ev
  }
  return $ NewEvaulation sk e

modifyEvaulationPost :: POSTContentHandler
modifyEvaulationPost = do
  ek <- getParamE (fieldName evaulationKeyField) EvaulationKey "Evaulation key does not found"
  ev <- getParamE (fieldName evaulationValueField) id "Evaulation value does not found"
  er <- getParamE (fieldName evaulationResultField)
                   (readMsg "Evaulation result")
                   "Evaulation result does not found"
  let e = C.Evaulation {
    evaulationResult = er
  , writtenEvaulation = ev
  }
  return $ C.ModifyEvaulation ek e

evaulationContent :: PageData -> Pagelet
evaulationContent pd = onlyHtml $ mkI18NHtml $ \i -> do
  let sd = sbmDesc pd
  H.p $ do
    (translate i "Information: Course, Group, Student")
    (fromString . eGroup   $ sd)
    (fromString . eStudent $ sd)
  H.p $ postForm (routeOf . evPage . sbmKey $ pd) $ do
          H.p $ do
            (translate i "Evaulation text block")
            textAreaInput (fieldName evaulationValueField) 50 10 Nothing
          H.p $ do
            (translate i "Evaulation checkbox, Submit button")
            -- TODO: Checkbox
          hiddenKeyField . sbmKey $ pd
          translate i . inputEvalResult . eConfig $ sd
          submitButton (fieldName saveEvalBtn) (i "Save Evaulation")
  H.p $ do
    (translate i "Submitted solution")
    (fromString . eSolution $ sd)
  translate i . commentsDiv . eComments $ sd

  where
    defaultEvalCfg :: EvaulationResult
    defaultEvalCfg = BinEval (Binary Passed)

    hiddenKeyField (Left ek)  = hiddenInput (fieldName evaulationKeyField) (paramValue ek)
    hiddenKeyField (Right sk) = hiddenInput (fieldName submissionKeyField) (paramValue sk)

    evPage (Left  _) = P.ModifyEvaulation
    evPage (Right _) = P.Evaulation

inputEvalResult :: EvaulationConfig -> I18NHtml
inputEvalResult (BinEval cfg) = mkI18NHtml $ \i -> do
  listSelection (fieldName evaulationResultField) $
    map binaryResult [(Passed, i "Passed"), (Failed, i "Failed")]
  where
    binaryResult :: (Result, String) -> (String, String)
    binaryResult (v,n) = (show . mkEvalResult . Binary $ v, n)

inputEvalResult (PctEval cfg) = mkI18NHtml $ \i -> do
  -- TODO: field validation
  (translate i "Evaulation between 0.0 and 1.0: ")
  textInput (fieldName evaulationResultField) 10 (Just . show $ 0.0)
