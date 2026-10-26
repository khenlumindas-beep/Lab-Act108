// Data models for the SmartTrack API.

const List<String> kMobilityTypes = [
  'Faculty Exchange',
  'Teaching Mobility',
  'Research Mobility',
  'International Training',
  'International Conference',
  'Visiting Professorship/Scholarship',
  'Fellowship',
  'Short-Term Study Program',
  'International Collaborative Research',
  'International Community Extension Engagement',
  'International Benchmarking',
  'Other',
];

const List<String> kFundingTypes = [
  'Fully Funded',
  'Partially Funded',
  'Self-Funded',
  'No Funding Required',
  'To Be Determined',
];

const List<String> kReadinessStatuses = ['Interested', 'Preparing', 'Ready'];

const List<String> kMobilityDurations = [
  'Short-Term',
  'Medium-Term',
  'Long-Term',
  'One Academic Term/Semester',
  'One Academic Year',
];

String _date(dynamic v) {
  final s = v?.toString() ?? '';
  return s.length >= 10 ? s.substring(0, 10) : s;
}

class College {
  College({required this.collegeId, required this.code, required this.name});
  final int collegeId;
  final String code;
  final String name;

  factory College.fromJson(Map<String, dynamic> j) => College(
        collegeId: j['college_id'] as int? ?? 0,
        code: j['code'] as String? ?? '',
        name: j['name'] as String? ?? '',
      );
}

class User {
  User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.designation,
    this.academicRank,
    this.collegeId,
    this.isActive = true,
  });
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final String? designation;
  final String? academicRank;
  final int? collegeId;
  final bool isActive;

  factory User.fromJson(Map<String, dynamic> j) => User(
        userId: j['user_id'] as int? ?? 0,
        fullName: j['full_name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'faculty',
        designation: j['designation'] as String?,
        academicRank: j['academic_rank'] as String?,
        collegeId: j['college_id'] as int?,
        isActive: j['is_active'] as bool? ?? true,
      );
}

class Travel {
  Travel({
    required this.travelId,
    required this.userId,
    required this.eventTitle,
    required this.mobilityType,
    required this.participantType,
    required this.startDate,
    required this.endDate,
    this.country,
    this.location,
    this.participantName,
    this.mobilityDuration,
    this.timelineStatus,
    this.followUp,
    this.riskFlag,
    this.preTravelStatus,
    this.postTravelStatus,
    this.movs,
    this.fundingType,
    this.docCompleteness,
    this.collegeId,
    this.remarks,
    this.workflowStatus,
    this.createdAt,
  });
  final int travelId;
  final int userId;
  final String eventTitle;
  final String mobilityType;
  final String participantType;
  final String startDate;
  final String endDate;
  final String? country;
  final String? location;
  final String? participantName;
  final String? mobilityDuration;
  final String? timelineStatus;
  final String? followUp;
  final String? riskFlag;
  final String? preTravelStatus;
  final String? postTravelStatus;
  final String? movs;
  final String? fundingType;
  final String? docCompleteness;
  final int? collegeId;
  final String? remarks;
  final String? workflowStatus;
  final String? createdAt;

  String get displayName =>
      participantType == 'Student' ? (participantName ?? 'Student') : '';

  factory Travel.fromJson(Map<String, dynamic> j) => Travel(
        travelId: j['travel_id'] as int? ?? 0,
        userId: j['user_id'] as int? ?? 0,
        eventTitle: j['event_title'] as String? ?? '',
        mobilityType: j['mobility_type'] as String? ?? '',
        participantType: j['participant_type'] as String? ?? 'Faculty',
        startDate: _date(j['start_date']),
        endDate: _date(j['end_date']),
        country: j['country'] as String?,
        location: j['location'] as String?,
        participantName: j['participant_name'] as String?,
        mobilityDuration: j['mobility_duration'] as String?,
        timelineStatus: j['timeline_status'] as String?,
        followUp: j['follow_up'] as String?,
        riskFlag: j['risk_flag'] as String?,
        preTravelStatus: j['pre_travel_status'] as String?,
        postTravelStatus: j['post_travel_status'] as String?,
        movs: j['movs'] as String?,
        fundingType: j['funding_type'] as String?,
        docCompleteness: j['doc_completeness'] as String?,
        collegeId: j['college_id'] as int?,
        remarks: j['remarks'] as String?,
        workflowStatus: j['workflow_status'] as String?,
        createdAt: j['created_at']?.toString(),
      );
}

/// Allowed travel-workflow transitions (mirrors backend constants.py).
const Map<String, List<String>> kWorkflowTransitions = {
  'Pending Requirements': ['Draft', 'Submitted', 'Cancelled'],
  'Draft': ['Pending Requirements', 'Submitted', 'Cancelled'],
  'Submitted': ['Under Review', 'Cancelled'],
  'Under Review': ['Incomplete', 'Approved', 'Cancelled'],
  'Incomplete': ['Submitted', 'Cancelled'],
  'Approved': ['Ongoing', 'Cancelled'],
  'Ongoing': ['Completed', 'Cancelled'],
  'Completed': <String>[],
  'Cancelled': <String>[],
};

/// Travel statuses that mean "cleared to travel" (post-approval).
const List<String> kForTravelStatuses = ['Approved', 'Ongoing', 'Completed'];

class DocumentRec {
  DocumentRec({
    required this.documentId,
    required this.travelId,
    required this.docType,
    this.docCategory,
    this.fileName,
    this.filePath,
    this.fileSize,
    this.status,
    this.remarks,
    this.uploadedAt,
  });
  final int documentId;
  final int travelId;
  final String docType;
  final String? docCategory;
  final String? fileName;
  final String? filePath;
  final int? fileSize;
  final String? status;
  final String? remarks;
  final String? uploadedAt;

  factory DocumentRec.fromJson(Map<String, dynamic> j) => DocumentRec(
        documentId: j['document_id'] as int? ?? 0,
        travelId: j['travel_id'] as int? ?? 0,
        docType: j['doc_type'] as String? ?? '',
        docCategory: j['doc_category'] as String?,
        fileName: j['file_name'] as String?,
        filePath: j['file_path'] as String?,
        fileSize: j['file_size'] as int?,
        status: j['status'] as String?,
        remarks: j['remarks'] as String?,
        uploadedAt: _date(j['uploaded_at']),
      );
}

class DocType {
  DocType({
    required this.docTypeId,
    required this.name,
    required this.category,
    this.isRequired = true,
    this.description,
    this.sortOrder = 0,
  });
  final int docTypeId;
  final String name;
  final String category;
  final bool isRequired;
  final String? description;
  final int sortOrder;

  factory DocType.fromJson(Map<String, dynamic> j) => DocType(
        docTypeId: j['doc_type_id'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? 'Pre-Travel',
        isRequired: j['is_required'] as bool? ?? true,
        description: j['description'] as String?,
        sortOrder: j['sort_order'] as int? ?? 0,
      );
}

class Announcement {
  Announcement({
    required this.announcementId,
    required this.title,
    required this.content,
    this.createdAt,
    this.isActive = true,
  });
  final int announcementId;
  final String title;
  final String content;
  final String? createdAt;
  final bool isActive;

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        announcementId: j['announcement_id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
        createdAt: j['created_at']?.toString(),
        isActive: j['is_active'] as bool? ?? true,
      );
}

class NotifItem {
  NotifItem({
    required this.notificationId,
    required this.title,
    required this.message,
    this.type,
    this.isRead = false,
    this.createdAt,
  });
  final int notificationId;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final String? createdAt;

  factory NotifItem.fromJson(Map<String, dynamic> j) => NotifItem(
        notificationId: j['notification_id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        message: j['message'] as String? ?? '',
        type: j['type'] as String?,
        isRead: j['is_read'] as bool? ?? false,
        createdAt: j['created_at']?.toString(),
      );
}

class Department {
  Department({
    required this.departmentId,
    required this.code,
    required this.name,
    required this.collegeId,
  });
  final int departmentId;
  final String code;
  final String name;
  final int collegeId;

  factory Department.fromJson(Map<String, dynamic> j) => Department(
        departmentId: j['department_id'] as int? ?? 0,
        code: j['code'] as String? ?? '',
        name: j['name'] as String? ?? '',
        collegeId: j['college_id'] as int? ?? 0,
      );
}

class Profile {
  Profile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.designation,
    this.academicRank,
    this.contactNumber,
    this.collegeId,
    this.collegeName,
    this.isActive = true,
  });
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final String? designation;
  final String? academicRank;
  final String? contactNumber;
  final int? collegeId;
  final String? collegeName;
  final bool isActive;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        userId: j['user_id'] as int? ?? 0,
        fullName: j['full_name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'faculty',
        designation: j['designation'] as String?,
        academicRank: j['academic_rank'] as String?,
        contactNumber: j['contact_number'] as String?,
        collegeId: j['college_id'] as int?,
        collegeName: (j['college'] as Map?)?['name'] as String?,
        isActive: j['is_active'] as bool? ?? true,
      );
}

/// ==================== PHASE 4: LIFECYCLE MODELS ====================

/// Post-travel requirement statuses (FR-F07, BR-05).
const List<String> kPostTravelStatuses = [
  'Not Submitted',
  'Submitted',
  'Verified',
  'Incomplete',
  'Waived',
];

/// Re-entry activity statuses (FR-F08, BR-06).
const List<String> kReentryStatuses = [
  'Not Started',
  'For Implementation',
  'Ongoing',
  'Completed',
  'Not Complied',
];

class PostTravelReq {
  PostTravelReq({
    required this.requirementId,
    required this.travelId,
    required this.requirement,
    this.docTypeId,
    this.dueDate,
    required this.status,
    this.evidencePath,
    this.completedAt,
    this.remarks,
  });

  final int requirementId;
  final int travelId;
  final String requirement;
  final int? docTypeId;
  final String? dueDate;
  final String status;
  final String? evidencePath;
  final String? completedAt;
  final String? remarks;

  bool get hasEvidence => evidencePath != null && evidencePath!.isNotEmpty;

  factory PostTravelReq.fromJson(Map<String, dynamic> j) => PostTravelReq(
        requirementId: j['requirement_id'] as int? ?? 0,
        travelId: j['travel_id'] as int? ?? 0,
        requirement: j['requirement'] as String? ?? '',
        docTypeId: j['doc_type_id'] as int?,
        dueDate: _date(j['due_date']),
        status: j['status'] as String? ?? 'Not Submitted',
        evidencePath: j['evidence_path'] as String?,
        completedAt: j['completed_at']?.toString(),
        remarks: j['remarks'] as String?,
      );
}

class ReentryActivity {
  ReentryActivity({
    required this.activityId,
    required this.travelId,
    required this.activity,
    this.description,
    this.targetDate,
    required this.status,
    this.evidencePath,
    this.completedAt,
    this.remarks,
  });

  final int activityId;
  final int travelId;
  final String activity;
  final String? description;
  final String? targetDate;
  final String status;
  final String? evidencePath;
  final String? completedAt;
  final String? remarks;

  bool get hasEvidence => evidencePath != null && evidencePath!.isNotEmpty;

  factory ReentryActivity.fromJson(Map<String, dynamic> j) => ReentryActivity(
        activityId: j['activity_id'] as int? ?? 0,
        travelId: j['travel_id'] as int? ?? 0,
        activity: j['activity'] as String? ?? '',
        description: j['description'] as String?,
        targetDate: _date(j['target_date']),
        status: j['status'] as String? ?? 'Not Started',
        evidencePath: j['evidence_path'] as String?,
        completedAt: j['completed_at']?.toString(),
        remarks: j['remarks'] as String?,
      );
}

/// Calculated compliance snapshot (FR-F09, BR-07). Never edited directly.
class ComplianceRec {
  ComplianceRec({
    required this.complianceId,
    required this.travelId,
    required this.status,
    required this.score,
    required this.preTravelOk,
    required this.postTravelOk,
    required this.reentryOk,
    required this.requiredDocs,
    required this.verifiedDocs,
    required this.priority,
    this.computedAt,
  });

  final int complianceId;
  final int travelId;
  final String status;
  final double score;
  final bool preTravelOk;
  final bool postTravelOk;
  final bool reentryOk;
  final int requiredDocs;
  final int verifiedDocs;
  final String priority;
  final String? computedAt;

  /// Percent complete, derived from the verified/required document counts.
  int get docPercent =>
      requiredDocs == 0 ? 0 : ((verifiedDocs / requiredDocs) * 100).round();

  factory ComplianceRec.fromJson(Map<String, dynamic> j) => ComplianceRec(
        complianceId: j['compliance_id'] as int? ?? 0,
        travelId: j['travel_id'] as int? ?? 0,
        status: j['status'] as String? ?? 'Needs Action',
        // Backend types score as Decimal, which Pydantic serializes to a
        // JSON string ("0.00"); tolerate num or String.
        score: double.tryParse('${j['score']}') ?? 0,
        preTravelOk: j['pre_travel_ok'] as bool? ?? false,
        postTravelOk: j['post_travel_ok'] as bool? ?? false,
        reentryOk: j['reentry_ok'] as bool? ?? false,
        requiredDocs: j['required_docs'] as int? ?? 0,
        verifiedDocs: j['verified_docs'] as int? ?? 0,
        priority: j['priority'] as String? ?? 'medium',
        computedAt: j['computed_at']?.toString(),
      );
}

class Siap {
  Siap({
    required this.internshipId,
    required this.studentName,
    required this.status,
    this.studentIdNo,
    this.collegeId,
    this.program,
    this.fheName,
    this.internshipStart,
    this.internshipEnd,
    this.milestone,
  });
  final int internshipId;
  final String studentName;
  final String status;
  final String? studentIdNo;
  final int? collegeId;
  final String? program;
  final String? fheName;
  final String? internshipStart;
  final String? internshipEnd;
  final String? milestone;

  factory Siap.fromJson(Map<String, dynamic> j) => Siap(
        internshipId: j['internship_id'] as int? ?? 0,
        studentName: j['student_name'] as String? ?? '',
        status: j['status'] as String? ?? 'Not Started',
        studentIdNo: j['student_id_no'] as String?,
        collegeId: j['college_id'] as int?,
        program: j['program'] as String?,
        fheName: j['fhe_name'] as String?,
        internshipStart: _date(j['internship_start']),
        internshipEnd: _date(j['internship_end']),
        milestone: j['milestone'] as String?,
      );
}

class MobilityPlan {
  MobilityPlan({
    required this.planId,
    this.preferredMobilityTypes,
    this.targetCountry,
    this.preferredPeriod,
    this.fundingNeeded = true,
    this.fundingType,
    this.readinessStatus = 'Interested',
    this.notes,
  });
  final int planId;
  final String? preferredMobilityTypes;
  final String? targetCountry;
  final String? preferredPeriod;
  final bool fundingNeeded;
  final String? fundingType;
  final String readinessStatus;
  final String? notes;

  factory MobilityPlan.fromJson(Map<String, dynamic> j) => MobilityPlan(
        planId: j['plan_id'] as int? ?? 0,
        preferredMobilityTypes: j['preferred_mobility_types'] as String?,
        targetCountry: j['target_country'] as String?,
        preferredPeriod: j['preferred_period'] as String?,
        fundingNeeded: j['funding_needed'] as bool? ?? true,
        fundingType: j['funding_type'] as String?,
        readinessStatus: j['readiness_status'] as String? ?? 'Interested',
        notes: j['notes'] as String?,
      );
}

/// ==================== PHASE 6: AUDIT & REMARK MODELS ====================

class AuditLogRow {
  AuditLogRow({
    required this.auditId,
    this.userId,
    this.entityType,
    this.entityId,
    required this.action,
    this.description,
    this.ipAddress,
    this.createdAt,
  });
  final int auditId;
  final int? userId;
  final String? entityType;
  final int? entityId;
  final String action;
  final String? description;
  final String? ipAddress;
  final String? createdAt;

  factory AuditLogRow.fromJson(Map<String, dynamic> j) => AuditLogRow(
        auditId: j['audit_id'] as int? ?? 0,
        userId: j['user_id'] as int?,
        entityType: j['entity_type'] as String?,
        entityId: j['entity_id'] as int?,
        action: j['action'] as String? ?? '',
        description: j['description'] as String?,
        ipAddress: j['ip_address'] as String?,
        createdAt: j['created_at']?.toString(),
      );
}

class RemarkRow {
  RemarkRow({
    required this.remarkId,
    this.travelId,
    this.documentId,
    this.adminId,
    this.remarkType,
    this.action,
    this.affectedRequirement,
    this.remarkText,
    this.previousStatus,
    this.newStatus,
    this.createdAt,
  });
  final int remarkId;
  final int? travelId;
  final int? documentId;
  final int? adminId;
  final String? remarkType;
  final String? action;
  final String? affectedRequirement;
  final String? remarkText;
  final String? previousStatus;
  final String? newStatus;
  final String? createdAt;

  factory RemarkRow.fromJson(Map<String, dynamic> j) => RemarkRow(
        remarkId: j['remark_id'] as int? ?? 0,
        travelId: j['travel_id'] as int?,
        documentId: j['document_id'] as int?,
        adminId: j['admin_id'] as int?,
        remarkType: j['remark_type'] as String?,
        action: j['action'] as String?,
        affectedRequirement: j['affected_requirement'] as String?,
        remarkText: j['remark_text'] as String?,
        previousStatus: j['previous_status'] as String?,
        newStatus: j['new_status'] as String?,
        createdAt: j['created_at']?.toString(),
      );
}

class DocAnalysis {
  DocAnalysis({
    required this.analysisId,
    required this.documentId,
    this.suggestedType,
    this.confidence,
    this.extractedText,
    this.issues,
    this.issueFlags,
    this.status,
    this.createdAt,
  });
  final int analysisId;
  final int documentId;
  final String? suggestedType;
  final double? confidence;
  final String? extractedText;
  final String? issues;
  final String? issueFlags;
  final String? status;
  final String? createdAt;

  List<String> get flags => (issueFlags == null || issueFlags!.isEmpty)
      ? <String>[]
      : issueFlags!.split(',').where((f) => f.trim().isNotEmpty).toList();

  factory DocAnalysis.fromJson(Map<String, dynamic> j) => DocAnalysis(
        analysisId: j['analysis_id'] as int? ?? 0,
        documentId: j['document_id'] as int? ?? 0,
        suggestedType: j['suggested_type'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble(),
        extractedText: j['extracted_text'] as String?,
        issues: j['issues'] as String?,
        issueFlags: j['issue_flags'] as String?,
        status: j['status'] as String?,
        createdAt: j['created_at']?.toString(),
      );
}

class AiInsight {
  AiInsight({
    required this.insightId,
    this.travelId,
    this.eventTitle,
    this.insightType,
    this.summary,
    this.priority,
    this.suggestedRemark,
    this.isAccepted,
    this.createdAt,
  });
  final int insightId;
  final int? travelId;
  final String? eventTitle;
  final String? insightType;
  final String? summary;
  final String? priority;
  final String? suggestedRemark;
  final bool? isAccepted;
  final String? createdAt;

  factory AiInsight.fromJson(Map<String, dynamic> j) => AiInsight(
        insightId: j['insight_id'] as int? ?? 0,
        travelId: j['travel_id'] as int?,
        eventTitle: j['event_title'] as String?,
        insightType: j['insight_type'] as String?,
        summary: j['summary'] as String?,
        priority: j['priority'] as String?,
        suggestedRemark: j['suggested_remark'] as String?,
        isAccepted: j['is_accepted'] as bool?,
        createdAt: j['created_at']?.toString(),
      );
}

class ReqItem {
  ReqItem({
    required this.requirementId,
    required this.name,
    required this.phase,
    this.parentId,
    this.isRequired = true,
    this.conditionText,
    this.displayText,
    this.hasTemplate = false,
    this.templateKey,
    this.sortOrder = 0,
    this.status,
    this.documentId,
    this.fileName,
    this.appliesTo,
  });
  final int requirementId;
  final String name;
  final String phase;
  final int? parentId;
  final bool isRequired;
  final String? conditionText;
  final String? displayText;
  final bool hasTemplate;
  final String? templateKey;
  final int sortOrder;
  final String? status;
  final int? documentId;
  final String? fileName;
  final String? appliesTo;

  factory ReqItem.fromJson(Map<String, dynamic> j) => ReqItem(
        requirementId: j['requirement_id'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        phase: j['phase'] as String? ?? 'Pre-Travel',
        parentId: j['parent_id'] as int?,
        isRequired: j['is_required'] as bool? ?? true,
        conditionText: j['condition_text'] as String?,
        displayText: j['display_text'] as String?,
        hasTemplate: j['has_template'] as bool? ?? false,
        templateKey: j['template_key'] as String?,
        sortOrder: j['sort_order'] as int? ?? 0,
        status: j['status'] as String?,
        documentId: j['document_id'] as int?,
        fileName: j['file_name'] as String?,
        appliesTo: j['applies_to'] as String?,
      );
}

class ReqStatus {
  ReqStatus({
    required this.travelId,
    required this.participantType,
    required this.items,
    required this.requiredTotal,
    required this.verifiedRequired,
    required this.percent,
    required this.complete,
    required this.checklistFiles,
  });
  final int travelId;
  final String participantType;
  final List<ReqItem> items;
  final int requiredTotal;
  final int verifiedRequired;
  final double percent;
  final bool complete;
  final List<String> checklistFiles;

  factory ReqStatus.fromJson(Map<String, dynamic> j) => ReqStatus(
        travelId: j['travel_id'] as int? ?? 0,
        participantType: j['participant_type'] as String? ?? 'Faculty',
        items: ((j['items'] as List?) ?? const [])
            .map((e) => ReqItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        requiredTotal: j['required_total'] as int? ?? 0,
        verifiedRequired: j['verified_required'] as int? ?? 0,
        percent: (j['percent'] as num?)?.toDouble() ?? 0,
        complete: j['complete'] as bool? ?? false,
        checklistFiles: ((j['checklist_files'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// One travel's completion row in the requirements compliance report.
class ReqReportRow {
  ReqReportRow({
    required this.travelId,
    required this.eventTitle,
    required this.facultyName,
    this.college,
    this.startDate,
    this.workflowStatus,
    required this.requiredTotal,
    required this.verifiedRequired,
    required this.percent,
    required this.complete,
    required this.missing,
  });
  final int travelId;
  final String eventTitle;
  final String facultyName;
  final String? college;
  final String? startDate;
  final String? workflowStatus;
  final int requiredTotal;
  final int verifiedRequired;
  final double percent;
  final bool complete;
  final List<String> missing;

  factory ReqReportRow.fromJson(Map<String, dynamic> j) => ReqReportRow(
        travelId: j['travel_id'] as int? ?? 0,
        eventTitle: j['event_title'] as String? ?? '',
        facultyName: j['faculty_name'] as String? ?? '',
        college: j['college'] as String?,
        startDate: j['start_date'] as String?,
        workflowStatus: j['workflow_status'] as String?,
        requiredTotal: j['required_total'] as int? ?? 0,
        verifiedRequired: j['verified_required'] as int? ?? 0,
        percent: (j['percent'] as num?)?.toDouble() ?? 0,
        complete: j['complete'] as bool? ?? false,
        missing: ((j['missing'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// Requirements compliance report: summary + per-travel rows.
class ReqReport {
  ReqReport({
    required this.appliesTo,
    required this.phase,
    required this.total,
    required this.complete,
    required this.incomplete,
    required this.notStarted,
    required this.avgPercent,
    required this.rows,
  });
  final String appliesTo;
  final String phase;
  final int total;
  final int complete;
  final int incomplete;
  final int notStarted;
  final double avgPercent;
  final List<ReqReportRow> rows;

  factory ReqReport.fromJson(Map<String, dynamic> j) {
    final s = Map<String, dynamic>.from(j['summary'] as Map? ?? const {});
    return ReqReport(
      appliesTo: j['applies_to'] as String? ?? 'Faculty',
      phase: j['phase'] as String? ?? 'Post-Travel',
      total: s['total'] as int? ?? 0,
      complete: s['complete'] as int? ?? 0,
      incomplete: s['incomplete'] as int? ?? 0,
      notStarted: s['not_started'] as int? ?? 0,
      avgPercent: (s['avg_percent'] as num?)?.toDouble() ?? 0,
      rows: ((j['rows'] as List?) ?? const [])
          .map((e) => ReqReportRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// One requirement's verdict from the heuristic AI check
/// (verdicts: verified | ai_ok | needs_review | missing | rejected | optional_missing).
class ReqAiItem {
  ReqAiItem({
    required this.requirementId,
    required this.name,
    required this.displayText,
    required this.isRequired,
    this.documentId,
    this.fileName,
    this.docStatus,
    required this.verdict,
    required this.reasons,
    required this.notes,
    this.confidence,
  });
  final int requirementId;
  final String name;
  final String displayText;
  final bool isRequired;
  final int? documentId;
  final String? fileName;
  final String? docStatus;
  final String verdict;
  final List<String> reasons;
  final List<String> notes;
  final double? confidence;

  factory ReqAiItem.fromJson(Map<String, dynamic> j) => ReqAiItem(
        requirementId: j['requirement_id'] as int? ?? 0,
        name: j['name'] as String? ?? '',
        displayText: j['display_text'] as String? ?? '',
        isRequired: j['is_required'] as bool? ?? true,
        documentId: j['document_id'] as int?,
        fileName: j['file_name'] as String?,
        docStatus: j['doc_status'] as String?,
        verdict: j['verdict'] as String? ?? 'missing',
        reasons: ((j['reasons'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        notes: ((j['notes'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        confidence: (j['confidence'] as num?)?.toDouble(),
      );
}

/// Aggregated AI-check counts for one travel.
class ReqAiSummary {
  ReqAiSummary({
    required this.requiredTotal,
    required this.verified,
    required this.aiOk,
    required this.needsReview,
    required this.missing,
    required this.rejected,
    required this.passed,
    required this.percent,
    required this.verdict,
  });
  final int requiredTotal;
  final int verified;
  final int aiOk;
  final int needsReview;
  final int missing;
  final int rejected;
  final int passed;
  final double percent;
  final String verdict;

  factory ReqAiSummary.fromJson(Map<String, dynamic> j) => ReqAiSummary(
        requiredTotal: j['required_total'] as int? ?? 0,
        verified: j['verified'] as int? ?? 0,
        aiOk: j['ai_ok'] as int? ?? 0,
        needsReview: j['needs_review'] as int? ?? 0,
        missing: j['missing'] as int? ?? 0,
        rejected: j['rejected'] as int? ?? 0,
        passed: j['passed'] as int? ?? 0,
        percent: (j['percent'] as num?)?.toDouble() ?? 0,
        verdict: j['verdict'] as String? ?? 'INCOMPLETE',
      );
}

/// Result of GET /requirements/ai-check/{travel_id} (heuristic AI review).
class ReqAiCheck {
  ReqAiCheck({
    required this.travelId,
    required this.summary,
    required this.items,
  });
  final int travelId;
  final ReqAiSummary summary;
  final List<ReqAiItem> items;

  Map<int, ReqAiItem> get byRequirementId =>
      {for (final i in items) i.requirementId: i};

  factory ReqAiCheck.fromJson(Map<String, dynamic> j) => ReqAiCheck(
        travelId: j['travel_id'] as int? ?? 0,
        summary: ReqAiSummary.fromJson(
            Map<String, dynamic>.from(j['summary'] as Map? ?? const {})),
        items: ((j['items'] as List?) ?? const [])
            .map((e) => ReqAiItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
