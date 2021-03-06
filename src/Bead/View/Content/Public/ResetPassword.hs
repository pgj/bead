{-# LANGUAGE OverloadedStrings #-}
module Bead.View.Content.Public.ResetPassword (
    emailSent
  , resetPassword
  ) where

import           Data.String (fromString)

import qualified Text.Blaze.Html5 as H

import           Bead.View.Content hiding (name)
import           Bead.View.Content.Bootstrap as Bootstrap
import           Bead.View.DataBridge (name)

{-
Renders the password reset request page. The page contains
two input fields for the user's name and the user's email
address. The user fills out the form, and clicks on "Reset password" button
and submit the requests.
-}
resetPassword :: IHtml
resetPassword = do
  msg <- getI18N
  return $ do
    Bootstrap.rowCol4Offset4 $ postForm "/reset_pwd" $ do
      Bootstrap.textInput (name regUsernamePrm) (msg $ msg_ResetPassword_Username "Username:") ""
      Bootstrap.textInput (name regEmailPrm)    (msg $ msg_ResetPassword_Email "Email") ""
      Bootstrap.submitButton (fieldName pwdSubmitBtn) (msg $ msg_ResetPassword_NewPwdButton "New password")
    Bootstrap.rowCol4Offset4 $ Bootstrap.buttonGroupJustified $
      Bootstrap.buttonLink "/" (msg $ msg_ResetPassword_GoBackToLogin "Back to login")

emailSent :: IHtml
emailSent = do
  msg <- getI18N
  return $ do
    Bootstrap.rowCol4Offset4 $ do
      H.p . fromString . msg $ msg_ResetPassword_EmailSent $ "The new password has been sent in email, it shall arrive soon."
    Bootstrap.rowCol4Offset4 $ Bootstrap.buttonGroupJustified $ do
      Bootstrap.buttonLink "/" (msg $ msg_ResetPassword_GoBackToLogin "Back to login")
