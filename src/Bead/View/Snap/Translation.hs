module Bead.View.Snap.Translation where

-- Translation is an enumeration all the possbile messages that could be rendered
-- on every page with the associated value.
data Translation a
  = Msg_Login_PageTitle { trans :: a }
  | Msg_Login_Neptun { trans :: a }
  | Msg_Login_Password { trans :: a }
  | Msg_Login_Submit { trans :: a }
  | Msg_Login_Title { trans :: a }
  | Msg_Login_Registration { trans :: a }
  | Msg_Login_Forgotten_Password { trans :: a }
  | Msg_Login_InternalError { trans :: a }

  | Msg_Routing_InvalidRoute { trans :: a }
  | Msg_Routing_SessionTimedOut { trans :: a }

  | Msg_ErrorPage_Title { trans :: a }
  | Msg_ErrorPage_GoBackToLogin { trans :: a }
  | Msg_ErrorPage_Header { trans :: a }

  | Msg_Input_Group_Name { trans :: a }
  | Msg_Input_Group_Description { trans :: a }
  | Msg_Input_Group_Evaluation { trans :: a }
  | Msg_Input_Course_Name { trans :: a }
  | Msg_Input_Course_Description { trans :: a }
  | Msg_Input_Course_Evaluation { trans :: a }
  | Msg_Input_User_Role { trans :: a }
  | Msg_Input_User_Email { trans :: a }
  | Msg_Input_User_FullName { trans :: a }
  | Msg_Input_User_TimeZone { trans :: a }
  | Msg_Input_User_Language { trans :: a }

  | Msg_CourseAdmin_CreateCourse { trans :: a }
  | Msg_CourseAdmin_AssignAdmin { trans :: a }
  | Msg_CourseAdmin_AssignAdmin_Button { trans :: a }
  | Msg_CourseAdmin_CreateGroup { trans :: a }
  | Msg_CourseAdmin_NoCourses { trans :: a }
  | Msg_CourseAdmin_Course { trans :: a }
  | Msg_CourseAdmin_PctHelpMessage { trans :: a }
  | Msg_CourseAdmin_NoGroups { trans :: a }
  | Msg_CourseAdmin_NoGroupAdmins { trans :: a }
  | Msg_CourseAdmin_Group { trans :: a }
  | Msg_CourseAdmin_Admin { trans :: a }

  | Msg_Administration_NewCourse { trans :: a }
  | Msg_Administration_PctHelpMessage { trans :: a }
  | Msg_Administration_CreatedCourses { trans :: a }
  | Msg_Administration_CreateCourse { trans :: a }
  | Msg_Administration_AssignCourseAdminTitle { trans :: a }
  | Msg_Administration_NoCourses { trans :: a }
  | Msg_Administration_NoCourseAdmins { trans :: a }
  | Msg_Administration_AssignCourseAdminButton { trans :: a }
  | Msg_Administration_ChangeUserProfile { trans :: a }
  | Msg_Administration_SelectUser { trans :: a }
  | Msg_Administration_HowToAddMoreAdmins { trans :: a }

  | Msg_NewAssignment_IsNoCourseAdmin { trans :: a }
  | Msg_NewAssignment_IsNoGroupAdmin { trans :: a }
  | Msg_NewAssignment_IsNoCreator { trans :: a }
  | Msg_NewAssignment_Title { trans :: a }
  | Msg_NewAssignment_SubmissionDeadline { trans :: a }
  | Msg_NewAssignment_StartDate { trans :: a }
  | Msg_NewAssignment_EndDate { trans :: a }
  | Msg_NewAssignment_Description { trans :: a }
  | Msg_NewAssignment_Markdown { trans :: a }
  | Msg_NewAssignment_CanBeUsed { trans :: a }
  | Msg_NewAssignment_Type { trans :: a }
  | Msg_NewAssignment_Course { trans :: a }
  | Msg_NewAssignment_Group { trans :: a }
  | Msg_NewAssignment_SaveButton { trans :: a }
  | Msg_NewAssignment_Title_Normal { trans :: a }
  | Msg_NewAssignment_Title_Urn { trans :: a }
  | Msg_NewAssignment_Info_Normal { trans :: a }
  | Msg_NewAssignment_Info_Urn { trans :: a }

  | Msg_GroupRegistration_RegisteredCourses { trans :: a }
  | Msg_GroupRegistration_SelectGroup { trans :: a }
  | Msg_GroupRegistration_NoRegisteredCourses { trans :: a }
  | Msg_GroupRegistration_Courses { trans :: a }
  | Msg_GroupRegistration_Admins { trans :: a }
  | Msg_GroupRegistration_NoAvailableCourses { trans :: a }
  | Msg_GroupRegistration_Register { trans :: a }
  | Msg_GroupRegistration_Unsubscribe { trans :: a }
  | Msg_GroupRegistration_NoUnsubscriptionAvailable { trans :: a }
  | Msg_GroupRegistration_Warning { trans :: a }

  | Msg_UserDetails_SaveButton { trans :: a }
  | Msg_UserDetails_NonExistingUser { trans :: a }

  | Msg_Submission_Course { trans :: a }
  | Msg_Submission_Admin { trans :: a }
  | Msg_Submission_Assignment { trans :: a }
  | Msg_Submission_Deadline { trans :: a }
  | Msg_Submission_Description { trans :: a }
  | Msg_Submission_Solution { trans :: a }
  | Msg_Submission_Submit { trans :: a }
  | Msg_Submission_Invalid_Assignment { trans :: a }

  | Msg_Comments_Title { trans :: a }
  | Msg_Comments_SubmitButton { trans :: a }

  | Msg_Evaluation_Title { trans :: a }
  | Msg_Evaluation_Course { trans :: a }
  | Msg_Evaluation_Student { trans :: a }
  | Msg_Evaluation_SaveButton { trans :: a }
  | Msg_Evaluation_Submited_Solution { trans :: a }
  | Msg_Evaluation_Accepted { trans :: a }
  | Msg_Evaluation_Rejected { trans :: a }
  | Msg_Evaluation_New_Comment { trans :: a }
  | Msg_Evaluation_Info { trans :: a }

  | Msg_SubmissionDetails_Course { trans :: a }
  | Msg_SubmissionDetails_Admins { trans :: a }
  | Msg_SubmissionDetails_Assignment { trans :: a }
  | Msg_SubmissionDetails_Deadline { trans :: a }
  | Msg_SubmissionDetails_Description { trans :: a }
  | Msg_SubmissionDetails_Solution { trans :: a }
  | Msg_SubmissionDetails_Evaluation { trans :: a }
  | Msg_SubmissionDetails_NewComment { trans :: a }
  | Msg_SubmissionDetails_SubmitComment { trans :: a }
  | Msg_SubmissionDetails_InvalidSubmission { trans :: a }

  | Msg_Registration_Title { trans :: a }
  | Msg_Registration_Neptun { trans :: a }
  | Msg_Registration_Email { trans :: a }
  | Msg_Registration_FullName { trans :: a }
  | Msg_Registration_SubmitButton { trans :: a }
  | Msg_Registration_GoBackToLogin { trans :: a }
  | Msg_Registration_InvalidNeptunCode { trans :: a }
  | Msg_Registration_HasNoUserAccess { trans :: a }
  | Msg_Registration_UserAlreadyExists { trans :: a }
  | Msg_Registration_RegistrationNotSaved { trans :: a }
  | Msg_Registration_EmailSubject { trans :: a }
  | Msg_Registration_EmailBody { trans :: a }
  | Msg_Registration_RequestParameterIsMissing { trans :: a }
  | Msg_Registration_GenericError { trans :: a }

  | Msg_RegistrationFinalize_NoRegistrationParametersAreFound { trans :: a }
  | Msg_RegistrationFinalize_SomeError { trans :: a }
  | Msg_RegistrationFinalize_InvalidToken { trans :: a }
  | Msg_RegistrationFinalize_UserAlreadyExist { trans :: a }
  | Msg_RegistrationFinalize_Password { trans :: a }
  | Msg_RegistrationFinalize_PwdAgain { trans :: a }
  | Msg_RegistrationFinalize_Timezone { trans :: a }
  | Msg_RegistrationFinalize_SubmitButton { trans :: a }
  | Msg_RegistrationFinalize_GoBackToLogin { trans :: a }

  | Msg_RegistrationCreateStudent_NoParameters { trans :: a }
  | Msg_RegistrationCreateStudent_InnerError { trans :: a }
  | Msg_RegistrationCreateStudent_InvalidToken { trans :: a }

  | Msg_RegistrationTokenSend_Title { trans :: a }
  | Msg_RegistrationTokenSend_StoryFailed { trans :: a }
  | Msg_RegistrationTokenSend_GoBackToLogin { trans :: a }

  | Msg_EvaluationTable_EmptyUnevaluatedSolutions { trans :: a }
  | Msg_EvaluationTable_Group { trans :: a }
  | Msg_EvaluationTable_Student { trans :: a }
  | Msg_EvaluationTable_Assignment { trans :: a }
  | Msg_EvaluationTable_Link { trans :: a }
  | Msg_EvaluationTable_Solution { trans :: a }
  | Msg_EvaluationTable_Info { trans :: a }

  | Msg_UserSubmissions_NonAccessibleSubmissions { trans :: a }
  | Msg_UserSubmissions_Course { trans :: a }
  | Msg_UserSubmissions_Assignment { trans :: a }
  | Msg_UserSubmissions_Student { trans :: a }
  | Msg_UserSubmissions_SubmittedSolutions { trans :: a }
  | Msg_UserSubmissions_SubmissionDate { trans :: a }
  | Msg_UserSubmissions_Evaluation { trans :: a }

  | Msg_UserSubmissions_Accepted { trans :: a }
  | Msg_UserSubmissions_Discarded { trans :: a }
  | Msg_UserSubmissions_NotFound { trans :: a }
  | Msg_UserSubmissions_NonEvaluated { trans :: a }

  | Msg_SubmissionList_CourseOrGroup { trans :: a }
  | Msg_SubmissionList_Admin { trans :: a }
  | Msg_SubmissionList_Assignment { trans :: a }
  | Msg_SubmissionList_Deadline { trans :: a }
  | Msg_SubmissionList_Description { trans :: a }
  | Msg_SubmissionList_SubmittedSolutions { trans :: a }
  | Msg_SubmissionList_NotEvaluatedYet { trans :: a }
  | Msg_SubmissionList_NoSubmittedSolutions { trans :: a }
  | Msg_SubmissionList_NonAssociatedAssignment { trans :: a }
  | Msg_SubmissionList_NonReachableAssignment { trans :: a }
  | Msg_SubmissionList_Info { trans :: a }

  | Msg_ResetPassword_UserDoesNotExist { trans :: a }
  | Msg_ResetPassword_PasswordIsSet { trans :: a }
  | Msg_ResetPassword_GoBackToLogin { trans :: a }
  | Msg_ResetPassword_Neptun { trans :: a }
  | Msg_ResetPassword_Email { trans :: a }
  | Msg_ResetPassword_NewPwdButton { trans :: a }
  | Msg_ResetPassword_EmailSent { trans :: a }
  | Msg_ResetPassword_ForgottenPassword { trans :: a }
  | Msg_ResetPassword_EmailSubject { trans :: a }
  | Msg_ResetPassword_EmailBody { trans :: a }
  | Msg_ResetPassword_GenericError { trans :: a }
  | Msg_ResetPassword_InvalidPassword { trans :: a }

  | Msg_Profile_User { trans :: a }
  | Msg_Profile_Email { trans :: a }
  | Msg_Profile_FullName { trans :: a }
  | Msg_Profile_Timezone { trans :: a }
  | Msg_Profile_SaveButton { trans :: a }
  | Msg_Profile_OldPassword { trans :: a }
  | Msg_Profile_NewPassword { trans :: a }
  | Msg_Profile_NewPasswordAgain { trans :: a }
  | Msg_Profile_ChangePwdButton { trans :: a }
  | Msg_Profile_Language { trans :: a }
  | Msg_Profile_PasswordHasBeenChanged { trans :: a }

  | Msg_SetUserPassword_NonRegisteredUser { trans :: a }
  | Msg_SetUserPassword_User { trans :: a }
  | Msg_SetUserPassword_NewPassword { trans :: a }
  | Msg_SetUserPassword_NewPasswordAgain { trans :: a }
  | Msg_SetUserPassword_SetButton { trans :: a }

  | Msg_InputHandlers_BinEval { trans :: a }
  | Msg_InputHandlers_PctEval { trans :: a }
  | Msg_InputHandlers_Role_Student { trans :: a }
  | Msg_InputHandlers_Role_GroupAdmin { trans :: a }
  | Msg_InputHandlers_Role_CourseAdmin { trans :: a }
  | Msg_InputHandlers_Role_Admin { trans :: a }

  | Msg_Home_NewSolution { trans :: a }
  | Msg_Home_AdminTasks { trans :: a }
  | Msg_Home_CourseAdminTasks { trans :: a }
  | Msg_Home_CourseAdministration_Info { trans :: a }
  | Msg_Home_NoCoursesYet { trans :: a }
  | Msg_Home_GroupAdminTasks { trans :: a }
  | Msg_Home_NoGroupsYet { trans :: a }
  | Msg_Home_StudentTasks { trans :: a }
  | Msg_Home_HasNoRegisteredCourses { trans :: a }
  | Msg_Home_HasNoAssignments { trans :: a }
  | Msg_Home_Course { trans :: a }
  | Msg_Home_CourseAdmin { trans :: a }
  | Msg_Home_Assignment { trans :: a }
  | Msg_Home_Deadline { trans :: a }
  | Msg_Home_Evaluation { trans :: a }
  | Msg_Home_ClosedSubmission { trans :: a }
  | Msg_Home_SubmissionCell_NoSubmission { trans :: a }
  | Msg_Home_SubmissionCell_NonEvaluated { trans :: a }
  | Msg_Home_SubmissionCell_Accepted { trans :: a }
  | Msg_Home_SubmissionCell_Rejected { trans :: a }
  | Msg_Home_SubmissionTable_NoCoursesOrStudents { trans :: a }

  | Msg_Home_SubmissionTable_StudentName { trans :: a}
  | Msg_Home_SubmissionTable_Username { trans :: a }
  | Msg_Home_SubmissionTable_Summary { trans :: a }

  | Msg_Home_SubmissionTable_Accepted { trans :: a }
  | Msg_Home_SubmissionTable_Rejected { trans :: a }
  | Msg_Home_NonBinaryEvaluation { trans :: a }
  | Msg_Home_HasNoSummary { trans :: a }
  | Msg_Home_NonPercentageEvaluation { trans :: a }
  | Msg_Home_DeleteUsersFromCourse { trans :: a }
  | Msg_Home_DeleteUsersFromGroup { trans :: a }

  | Msg_UserStory_SetTimeZone { trans :: a }
  | Msg_UserStory_ChangedUserDetails { trans :: a }
  | Msg_UserStory_CreateCourse { trans :: a }
  | Msg_UserStory_SetCourseAdmin { trans :: a }
  | Msg_UserStory_SetGroupAdmin { trans :: a }
  | Msg_UserStory_CreateGroup { trans :: a }
  | Msg_UserStory_SubscribedToGroup { trans :: a }
  | Msg_UserStory_SubscribedToGroup_ChangeNotAllowed { trans :: a }
  | Msg_UserStory_NewGroupAssignment { trans :: a }
  | Msg_UserStory_NewCourseAssignment { trans :: a }
  | Msg_UserStory_UsersAreDeletedFromCourse { trans :: a }
  | Msg_UserStory_UsersAreDeletedFromGroup { trans :: a }
  | Msg_UserStory_SuccessfulCourseUnsubscription { trans :: a }

  | Msg_UserActions_ChangedUserDetails { trans :: a }

  | Msg_LinkText_Login { trans :: a }
  | Msg_LinkText_Logout { trans :: a }
  | Msg_LinkText_Home { trans :: a }
  | Msg_LinkText_Profile { trans :: a }
  | Msg_LinkText_Error { trans :: a }
  | Msg_LinkText_CourseAdministration { trans :: a }
  | Msg_LinkText_Submission { trans :: a }
  | Msg_LinkText_SubmissionList { trans :: a }
  | Msg_LinkText_UserSubmissions { trans :: a }
  | Msg_LinkText_ModifyEvaluation { trans :: a }
  | Msg_LinkText_SubmissionDetails { trans :: a }
  | Msg_LinkText_Administration { trans :: a }
  | Msg_LinkText_Evaluation { trans :: a }
  | Msg_LinkText_EvaluationTable { trans :: a }
  | Msg_LinkText_GroupRegistration { trans :: a }
  | Msg_LinkText_CreateCourse { trans :: a }
  | Msg_LinkText_UserDetails { trans :: a }
  | Msg_LinkText_AssignCourseAdmin { trans :: a }
  | Msg_LinkText_CreateGroup { trans :: a }
  | Msg_LinkText_AssignGroupAdmin { trans :: a }
  | Msg_LinkText_NewGroupAssignment { trans :: a }
  | Msg_LinkText_NewCourseAssignment { trans :: a }
  | Msg_LinkText_ModifyAssignment { trans :: a }
  | Msg_LinkText_ChangePassword { trans :: a }
  | Msg_LinkText_SetUserPassword { trans :: a }
  | Msg_LinkText_CommentFromEvaluation { trans :: a }
  | Msg_LinkText_CommentFromModifyEvaluation { trans :: a }
  | Msg_LinkText_DeleteUsersFromCourse { trans :: a }
  | Msg_LinkText_DeleteUsersFromGroup { trans :: a }
  | Msg_LinkText_UnsubscribeFromCourse { trans :: a }

  deriving (Show, Read, Eq, Ord)
