// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MedLink';

  @override
  String get tagline => 'AI-powered healthcare platform';

  @override
  String get onb1Title => 'AI checks your symptoms';

  @override
  String get onb1Body =>
      'Describe what bothers you — Google Med-PaLM 2 tells you how urgent it is and which doctor to see.';

  @override
  String get onb2Title => 'Only verified doctors';

  @override
  String get onb2Body =>
      'Every doctor’s diploma and license are checked by moderators. Book a visit in a few taps.';

  @override
  String get onb3Title => 'Your data is protected';

  @override
  String get onb3Body =>
      'Medical data is encrypted, used only with your consent and can be deleted at any time.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get phoneTitle => 'Your phone number';

  @override
  String get phoneSubtitle => 'We\'ll text you a sign-in code';

  @override
  String get getCode => 'Get code';

  @override
  String get loginLegal =>
      'By continuing you agree to review the terms of use and privacy policy.';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSubtitle(String phone) {
    return 'We sent a 6-digit code to $phone';
  }

  @override
  String get login => 'Sign in';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get deleted => 'Deleted';

  @override
  String get retry => 'Try again';

  @override
  String get loading => 'Loading';

  @override
  String get submit => 'Submit';

  @override
  String get add => 'Add';

  @override
  String get clear => 'Clear';

  @override
  String get all => 'All';

  @override
  String get seeAll => 'See all';

  @override
  String get required => 'required';

  @override
  String get requiredField => 'Required field';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutConfirm => 'Sign out of your account?';

  @override
  String get systemDefault => 'System default';

  @override
  String get today => 'Today';

  @override
  String get errorGeneric => 'Something went wrong. Please try again';

  @override
  String get errorNetwork => 'No internet connection';

  @override
  String get errorOtpInvalid => 'Incorrect code';

  @override
  String get errorOtpExpired => 'The code has expired. Request a new one';

  @override
  String get errorOtpAttempts => 'Too many attempts. Request a new code';

  @override
  String get errorRateLimited => 'Too many requests. Try again later';

  @override
  String get errorConsentRequired => 'Your consent is required for this';

  @override
  String get errorSlotUnavailable => 'This time is taken. Choose another one';

  @override
  String get errorAlreadyApplied => 'You have already applied';

  @override
  String get errorNotPayable => 'This appointment cannot be paid';

  @override
  String get errorNotStarted => 'The visit has not started yet';

  @override
  String get errorAlreadyReviewed => 'You have already left a review';

  @override
  String get consentScreenTitle => 'Consent & privacy';

  @override
  String get consentIntro =>
      'Read how your data is used and decide on each item separately. The service cannot work without the required items.';

  @override
  String consentFooter(String version) {
    return 'Version: $version. The time of your decision and device details are stored as evidence.';
  }

  @override
  String get agreeContinue => 'Agree and continue';

  @override
  String get consentSettings => 'Consent settings';

  @override
  String get withdrawTitle => 'Withdraw consent';

  @override
  String get withdrawMessage =>
      'If you withdraw a required consent you will not be able to use the service. Continue?';

  @override
  String get withdrawConfirm => 'Yes, withdraw';

  @override
  String get consentTermsTitle => 'Terms of use';

  @override
  String get consentTermsSummary => 'Rules for using MedLink.';

  @override
  String get consentTermsBody =>
      'MedLink is an information platform connecting patients with licensed doctors. It does not provide medical care and does not replace emergency services. In life-threatening situations call 103. Doctors’ diplomas and licenses are verified by moderators.';

  @override
  String get consentPersonalTitle => 'Personal data';

  @override
  String get consentPersonalSummary =>
      'Storing your phone number and profile data.';

  @override
  String get consentPersonalBody =>
      'In accordance with the Law on Personal Data, your phone number, name and visit history are processed to provide the service and stored encrypted. You may at any time obtain a copy of your data or request its correction or deletion.';

  @override
  String get consentHealthTitle => 'Health data';

  @override
  String get consentHealthSummary =>
      'Storing symptoms, visit reasons and your medical profile.';

  @override
  String get consentHealthBody =>
      'Health data is a special category of data. It is encrypted with AES-256 and visible only to you and the doctor you choose. Every access is recorded in an audit log. Data is never shared with third parties for advertising.';

  @override
  String get consentAiTitle => 'AI analysis';

  @override
  String get consentAiSummary =>
      'Analysing your symptoms with Google Med-PaLM 2.';

  @override
  String get consentAiBody =>
      'If you use AI analysis, the text you enter, your age and sex are sent to the model. Your name, phone and other identifiers are not sent. The result is not a diagnosis. Withdrawing consent deletes your AI history. This consent is optional.';

  @override
  String get consentTransferTitle => 'Cross-border transfer';

  @override
  String get consentTransferSummary =>
      'For AI analysis, de-identified text is sent to Google Cloud.';

  @override
  String get consentTransferBody =>
      'The AI model runs on Google Cloud servers outside Uzbekistan. De-identified symptom text is sent over an encrypted (TLS) channel. This consent is required for AI analysis.';

  @override
  String get consentMarketingTitle => 'News and offers';

  @override
  String get consentMarketingSummary =>
      'Messages about news and special offers.';

  @override
  String get consentMarketingBody =>
      'Optional. You can turn it off in settings at any time.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabDoctors => 'Doctors';

  @override
  String get tabAppointments => 'Visits';

  @override
  String get tabPatients => 'Patients';

  @override
  String get tabModeration => 'Moderation';

  @override
  String get tabProfile => 'Profile';

  @override
  String get goodMorning => 'Good morning!';

  @override
  String get goodAfternoon => 'Good afternoon!';

  @override
  String get goodEvening => 'Good evening!';

  @override
  String get homeSubtitle => 'How can we help your health today?';

  @override
  String get aiCardTitle => 'Check your symptoms';

  @override
  String get aiCardBody =>
      'Describe what bothers you — AI suggests which doctor to see.';

  @override
  String get nextAppointment => 'Next visit';

  @override
  String get specialists => 'Specialists';

  @override
  String emergencyBanner(String phone) {
    return 'In a life-threatening emergency call $phone now';
  }

  @override
  String callEmergency(String phone) {
    return 'Call $phone';
  }

  @override
  String get triageTitle => 'AI symptom check';

  @override
  String get triageHistory => 'Check history';

  @override
  String get triageHistoryEmpty => 'No checks yet';

  @override
  String get aiConsentNeededTitle => 'Consent needed for AI analysis';

  @override
  String get aiConsentNeededBody =>
      'Grant the “AI analysis” and “Cross-border transfer” consents. This is optional — you can book a doctor without it.';

  @override
  String get symptomsQuestion => 'What is bothering you?';

  @override
  String get symptomsHint =>
      'E.g.: fever of 38.5 for 3 days, sore throat, pain when swallowing...';

  @override
  String get noPiiHint =>
      'Do not include your name, phone or passport details.';

  @override
  String get age => 'Age';

  @override
  String get durationDays => 'Duration (days)';

  @override
  String get female => 'Female';

  @override
  String get male => 'Male';

  @override
  String get prefilledFromProfile => 'Filled from your medical profile';

  @override
  String chronicIncluded(String list) {
    return 'Will be considered: $list';
  }

  @override
  String get analyze => 'Analyse';

  @override
  String get analyzing => 'Analysing...';

  @override
  String get triagePoweredBy =>
      'Analysis is performed by Google Med-PaLM 2 and is not a diagnosis.';

  @override
  String get resultTitle => 'Result';

  @override
  String get urgencyEmergency => 'Emergency care needed';

  @override
  String urgencyEmergencyBody(String phone) {
    return 'Call $phone immediately or go to the nearest hospital.';
  }

  @override
  String get urgencyUrgent => 'See a doctor soon';

  @override
  String get urgencyUrgentBody => 'Book a visit for today or tomorrow.';

  @override
  String get urgencyRoutine => 'Routine visit';

  @override
  String get urgencyRoutineBody => 'See a doctor in the coming days.';

  @override
  String get urgencySelfCare => 'Self-care at home';

  @override
  String get urgencySelfCareBody => 'If it gets worse, see a doctor.';

  @override
  String get redFlags => 'Warning signs';

  @override
  String get possibleCauses => 'Possible causes';

  @override
  String get likelihoodHigh => 'High';

  @override
  String get likelihoodMedium => 'Medium';

  @override
  String get likelihoodLow => 'Low';

  @override
  String get advice => 'Advice';

  @override
  String get whichDoctor => 'Which doctor to see';

  @override
  String findSpecialist(String specialty) {
    return 'Find a $specialty';
  }

  @override
  String get disclaimer =>
      'This analysis is not a diagnosis and does not replace a doctor’s examination.';

  @override
  String get searchDoctors => 'Doctor or clinic';

  @override
  String get noDoctorsFound => 'No doctors found';

  @override
  String get noDoctorsFoundHint => 'Try another specialty or search';

  @override
  String get verifiedLicense => 'License verified';

  @override
  String yearsExperience(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years experience',
      one: '$count year experience',
    );
    return '$_temp0';
  }

  @override
  String get experienceLabel => 'Years exp.';

  @override
  String get rating => 'Rating';

  @override
  String get reviews => 'Reviews';

  @override
  String get about => 'About';

  @override
  String consultationPrice(String price) {
    return 'Consultation: $price';
  }

  @override
  String get patientReviews => 'Patient reviews';

  @override
  String get chooseDay => 'Choose a day';

  @override
  String get chooseTime => 'Choose a time';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get noSlots => 'No free time on this day';

  @override
  String get visitReason => 'Reason for visit';

  @override
  String get visitReasonHint => 'Visible only to the doctor';

  @override
  String bookFor(String when, String price) {
    return 'Book · $when · $price';
  }

  @override
  String get holdNotice =>
      'The slot is held for 15 minutes — please pay within that time.';

  @override
  String priceUzs(String amount) {
    return '$amount UZS';
  }

  @override
  String get payment => 'Payment';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get localCards => 'Uzcard, Humo';

  @override
  String get intlCards => 'Visa, Mastercard';

  @override
  String payAmount(String price) {
    return 'Pay · $price';
  }

  @override
  String get pay => 'Pay';

  @override
  String get checkPayment => 'Check payment';

  @override
  String get paymentNotYet =>
      'Payment is not confirmed yet. Check again shortly.';

  @override
  String get paymentFailed => 'Payment failed';

  @override
  String get cardSafety => 'Card details are never stored on MedLink servers.';

  @override
  String holdLeft(String time) {
    return 'Hold expires in $time';
  }

  @override
  String get holdExpired => 'The hold has expired. Please choose a time again.';

  @override
  String get appointmentConfirmed => 'Visit confirmed!';

  @override
  String get backToHome => 'Back to home';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get past => 'Past';

  @override
  String get noUpcoming => 'No upcoming visits';

  @override
  String get noPast => 'No past visits';

  @override
  String get findDoctor => 'Find a doctor';

  @override
  String get statusAwaitingPayment => 'Awaiting payment';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get appointmentDetails => 'Visit details';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get clinicLabel => 'Clinic';

  @override
  String get priceLabel => 'Price';

  @override
  String get cancelAppointment => 'Cancel visit';

  @override
  String get cancelAppointmentConfirm =>
      'Do you really want to cancel this visit?';

  @override
  String get rateDoctor => 'Rate the doctor';

  @override
  String get reviewHint => 'Tell us about your visit (optional)';

  @override
  String get yourReview => 'Your review';

  @override
  String get doctorApplication => 'Doctor application';

  @override
  String get moderationHowTitle => 'How moderation works';

  @override
  String get moderationHowBody =>
      'We check your diploma, license (Ministry of Health registry) and ID. Once approved, your profile becomes visible to patients with a “verified” badge. Usually 1–3 business days.';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameInvalid => 'Enter your full name';

  @override
  String get specialty => 'Specialty';

  @override
  String get licenseNumber => 'License number';

  @override
  String get city => 'City';

  @override
  String get experienceYearsLabel => 'Experience (years)';

  @override
  String get priceUzsLabel => 'Price (UZS)';

  @override
  String get aboutYou => 'About you';

  @override
  String get documents => 'Documents';

  @override
  String get documentsHint =>
      'Links to copies of diploma, license, passport (one per line)';

  @override
  String get applicationConfirm =>
      'I confirm the information is accurate and agree to its verification';

  @override
  String get sendApplication => 'Submit application';

  @override
  String get applicationSent =>
      'Application sent. Moderation takes 1–3 business days.';

  @override
  String get noPatients => 'No patients booked yet';

  @override
  String get noReason => 'No reason given';

  @override
  String get completeVisit => 'Complete visit';

  @override
  String get completeVisitConfirm =>
      'Confirm the visit took place? The patient will then be able to leave a review.';

  @override
  String get noPending => 'No applications to review';

  @override
  String get approve => 'Approve';

  @override
  String approveConfirm(String name) {
    return 'Approve $name? The profile will become visible to patients.';
  }

  @override
  String get reject => 'Reject';

  @override
  String get rejectReason => 'Reason for rejection';

  @override
  String get rejectReasonHint => 'E.g.: license not found in the registry';

  @override
  String get patient => 'Patient';

  @override
  String get rolePatient => 'Patient';

  @override
  String get roleDoctor => 'Doctor';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get health => 'Health';

  @override
  String get medicalProfile => 'Medical profile';

  @override
  String get medicalProfileSubtitle =>
      'Allergies, chronic conditions, medications';

  @override
  String get medicalProfileNote =>
      'Stored encrypted and automatically included in AI analysis.';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get bloodType => 'Blood type';

  @override
  String get heightCm => 'Height (cm)';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get allergies => 'Allergies';

  @override
  String get allergiesHint => 'E.g.: penicillin';

  @override
  String get chronicConditions => 'Chronic conditions';

  @override
  String get chronicHint => 'E.g.: type 2 diabetes';

  @override
  String get medications => 'Regular medications';

  @override
  String get medicationsHint => 'E.g.: metformin 500 mg';

  @override
  String get forDoctors => 'For doctors';

  @override
  String get becomeDoctor => 'Join as a doctor';

  @override
  String get becomeDoctorSubtitle => 'Apply and pass moderation';

  @override
  String get applicationPending => 'Application under review';

  @override
  String get applicationApproved => 'Verified doctor';

  @override
  String get applicationRejected => 'Application rejected';

  @override
  String get applicationSuspended => 'Profile suspended';

  @override
  String moderatorNote(String note) {
    return 'Moderator note: $note';
  }

  @override
  String get reapply => 'Apply again';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get biometricLock => 'Biometric lock';

  @override
  String get biometricLockSubtitle => 'Unlock with Face ID / fingerprint';

  @override
  String get biometricReason => 'Confirm your identity to open MedLink';

  @override
  String get lockedTitle => 'MedLink is locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get privacy => 'Privacy';

  @override
  String get exportData => 'Export my data';

  @override
  String get exportDataSubtitle => 'Get all data stored about you';

  @override
  String get exportCopied => 'A copy of your data was copied to the clipboard';

  @override
  String get deleteHealthData => 'Delete health data';

  @override
  String get deleteHealthDataConfirm =>
      'AI checks and your medical profile will be permanently deleted. Visit history is kept for the period required by law.';

  @override
  String get emergencyNumber => 'Emergency';

  @override
  String get version => 'Version';

  @override
  String get specTherapist => 'General practitioner';

  @override
  String get specPediatrician => 'Pediatrician';

  @override
  String get specCardiologist => 'Cardiologist';

  @override
  String get specNeurologist => 'Neurologist';

  @override
  String get specGastroenterologist => 'Gastroenterologist';

  @override
  String get specPulmonologist => 'Pulmonologist';

  @override
  String get specEndocrinologist => 'Endocrinologist';

  @override
  String get specDermatologist => 'Dermatologist';

  @override
  String get specEnt => 'ENT';

  @override
  String get specOphthalmologist => 'Ophthalmologist';

  @override
  String get specGynecologist => 'Gynecologist';

  @override
  String get specUrologist => 'Urologist';

  @override
  String get specTraumatologist => 'Traumatologist';

  @override
  String get specPsychiatrist => 'Psychiatrist';

  @override
  String get tashkentTime => 'Tashkent time (UTC+5)';

  @override
  String get completeProfile => 'Complete your profile';

  @override
  String get licenses => 'Licenses';

  @override
  String get reminderTitle => 'MedLink: visit reminder';

  @override
  String reminderDayBefore(String time) {
    return 'You have a visit tomorrow at $time.';
  }

  @override
  String reminderHourBefore(String time) {
    return 'Your visit is in 1 hour, at $time.';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Visit reminders and status updates';

  @override
  String get notificationsDenied =>
      'Permission denied. Enable notifications for MedLink in your phone settings.';

  @override
  String get enableRemindersTitle => 'Don\'t miss your visit';

  @override
  String get enableRemindersBody =>
      'We\'ll remind you a day and an hour before. No medical details are shown.';

  @override
  String get enableReminders => 'Turn on reminders';

  @override
  String get remindersEnabled => 'Reminders are on';

  @override
  String get online => 'Online';

  @override
  String get inClinic => 'In clinic';

  @override
  String get onlineAvailable => 'Online visits';

  @override
  String get onlineOnly => 'Online visits only';

  @override
  String get consultationType => 'Visit type';

  @override
  String get consultationTypes => 'Visit types';

  @override
  String get onlineHowItWorks =>
      'A video call opens in the app at your visit time. Prepare a stable connection and a quiet place.';

  @override
  String onlinePriceLabel(String price) {
    return 'Online visit: $price';
  }

  @override
  String get onlineConsultation => 'Online consultation';

  @override
  String get joinVideo => 'Join video call';

  @override
  String get videoReady => 'The room is open. Join to connect.';

  @override
  String get videoReadyShort => 'Video ready';

  @override
  String videoOpensAt(String time) {
    return 'Video opens at $time (10 minutes before the visit).';
  }

  @override
  String get videoClosed =>
      'The video window has ended. Use the chat for questions.';

  @override
  String get videoNotConfigured =>
      'Video is not set up yet. Please use the chat.';

  @override
  String get videoTips => 'Tip: use headphones and sit in a well-lit place.';

  @override
  String get callConnecting => 'Connecting...';

  @override
  String get callWaiting => 'Waiting for the other side to join...';

  @override
  String get callReconnecting => 'Connection lost, reconnecting...';

  @override
  String get callEnded => 'Call ended';

  @override
  String get callFailed =>
      'Could not connect. Check your internet and try again.';

  @override
  String get callPermissionDenied =>
      'Camera or microphone access denied. Allow it for MedLink in settings.';

  @override
  String get callEncrypted => 'Encrypted · not recorded';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get cameraOff => 'Camera off';

  @override
  String get cameraOn => 'Camera on';

  @override
  String get switchCamera => 'Flip';

  @override
  String get endCall => 'End';

  @override
  String get endCallConfirm => 'End the call?';

  @override
  String get close => 'Close';

  @override
  String get chat => 'Chat';

  @override
  String get chatSubtitle => 'Ask your doctor';

  @override
  String get chatSubtitleDoctor => 'Messages with the patient';

  @override
  String get chatHint => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get sending => 'Sending';

  @override
  String get chatEmptyTitle => 'No messages yet';

  @override
  String get chatEmptyBody =>
      'Ask a question about your visit. The doctor replies during working hours.';

  @override
  String get chatClosed => 'Chat closed: 7 days have passed since the visit.';

  @override
  String get chatEmergencyNote =>
      'Chat is not for emergencies — call 103 if your life is at risk';

  @override
  String get patientInfo => 'Patient information';

  @override
  String get patientInfoSubtitle => 'Medical profile and AI check';

  @override
  String get aiPreTriage => 'Pre-visit AI check';

  @override
  String get viewDetails => 'View details';

  @override
  String get sex => 'Sex';

  @override
  String get heightWeight => 'Height / weight';

  @override
  String get patientReview => 'Patient review';

  @override
  String get conclusion => 'Doctor\'s summary';

  @override
  String get writeConclusion => 'Write summary';

  @override
  String get editConclusion => 'Edit summary';

  @override
  String get saveConclusion => 'Save summary';

  @override
  String get saveConclusionConfirm =>
      'The summary will be sent to the patient and the visit completed. Continue?';

  @override
  String get conclusionSaved => 'Summary saved and sent to the patient';

  @override
  String get diagnosis => 'Diagnosis';

  @override
  String get diagnosisHint => 'E.g.: Acute respiratory infection (J06.9)';

  @override
  String get recommendations => 'Recommendations';

  @override
  String get prescription => 'Prescription';

  @override
  String get addMedication => 'Add medication';

  @override
  String get noPrescription => 'No medication prescribed';

  @override
  String get medication => 'Medication';

  @override
  String get drugName => 'Drug name';

  @override
  String get dose => 'Dose';

  @override
  String get frequency => 'How to take';

  @override
  String get frequencyHint => 'E.g.: twice a day after meals';

  @override
  String get notes => 'Notes';

  @override
  String get followUp => 'Follow-up';

  @override
  String get followUpNone => 'Not needed';

  @override
  String inDays(int days) {
    return 'in $days days';
  }

  @override
  String forDays(int days) {
    return '$days days';
  }

  @override
  String followUpIn(int days) {
    return 'Follow-up in $days days';
  }

  @override
  String get conclusionPrivacy =>
      'The summary is stored encrypted and visible only to the patient.';

  @override
  String get conclusionDisclaimer =>
      'Take medication only as prescribed. If you feel worse, call 103.';

  @override
  String get scheduleAndPrices => 'Schedule and prices';

  @override
  String get scheduleAndPricesSubtitle => 'Work days, hours, online visits';

  @override
  String get workDays => 'Work days';

  @override
  String get workHours => 'Working hours (Tashkent time)';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String slotsPerDay(int count) {
    return '$count 30-minute visits per day';
  }

  @override
  String get clinicPrice => 'Clinic visit price';

  @override
  String get onlinePrice => 'Online visit price';

  @override
  String get onlineSubtitle => 'Via video call and chat';

  @override
  String get scheduleNote =>
      'Changes apply to new bookings only. Existing visits are kept.';

  @override
  String get chooseConsultationType => 'Enable at least one visit type';

  @override
  String get onlinePriceRequired => 'Enter the online visit price';

  @override
  String get errorChatClosed => 'Chat is closed';

  @override
  String get errorTooEarly =>
      'Video is not open yet — it opens 10 minutes before the visit';

  @override
  String get errorTooLate => 'The video window has ended';

  @override
  String get errorVideoUnavailable => 'Video is temporarily unavailable';

  @override
  String get errorTypeUnavailable =>
      'The doctor does not offer this visit type';

  @override
  String get errorInvalidSchedule => 'Invalid schedule: check days and hours';

  @override
  String get videoNotConfiguredDoctor =>
      'Video is not set up yet. Please use the chat with the patient.';

  @override
  String get tabAdmin => 'Admin';

  @override
  String get statistics => 'Statistics';

  @override
  String get applications => 'Applications';

  @override
  String get refunds => 'Refunds';

  @override
  String get statUsers => 'Users';

  @override
  String get statDoctors => 'Active doctors';

  @override
  String get statPendingApplications => 'Pending applications';

  @override
  String get statToday => 'Visits today';

  @override
  String get statRevenue30d => '30-day revenue';

  @override
  String get statOnlineShare => 'Online share';

  @override
  String get statRefundsPending => 'Refunds pending';

  @override
  String get statAppointments => 'Visits by status';

  @override
  String get noRefunds => 'No pending refunds';

  @override
  String get refundReasonDoctor => 'Cancelled by the doctor';

  @override
  String get refundReasonPatient => 'Cancelled by the patient over 24h ahead';

  @override
  String get markRefunded => 'Mark as refunded';

  @override
  String markRefundedConfirm(String provider) {
    return 'First issue the refund in the $provider merchant dashboard. The patient will be notified. Continue?';
  }

  @override
  String requestedAt(String time) {
    return 'Requested: $time';
  }

  @override
  String transactionId(String id) {
    return 'Transaction: $id';
  }

  @override
  String get copied => 'Copied';

  @override
  String get cancelPolicyRefund =>
      'More than 24 hours before the visit — you will get a full refund. Cancel?';

  @override
  String get cancelPolicyNoRefund =>
      'Less than 24 hours before the visit — the payment is not refunded. Cancel anyway?';

  @override
  String get cancelPolicyDoctor =>
      'The patient will get a full refund and a notification. Cancel?';

  @override
  String get refundRequested =>
      'Visit cancelled. Your payment will be refunded within 3–5 business days.';

  @override
  String get refundRequestedShort => 'Refund in progress';

  @override
  String get refundDone => 'Refunded';

  @override
  String get attachPhoto => 'Attach photo';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get attachmentHint =>
      'You can send a photo of test results, a prescription or a skin change. Photos are encrypted and location data is removed.';

  @override
  String get uploadingPhoto => 'Sending photo...';

  @override
  String get errorFileTooLarge => 'File is too large (max 5 MB)';

  @override
  String get errorUnsupportedFile => 'Only JPEG or PNG images are supported';
}
