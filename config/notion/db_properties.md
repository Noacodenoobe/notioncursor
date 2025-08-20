# Notion Database Properties Mapping

This document describes the field mappings for all Notion databases used in the BWS Stack.

## 📋 Tasks Database

**Database ID**: `NOTION_DATABASE_ID_TASKS`

| Property Name | Type | Description | Required |
|---------------|------|-------------|----------|
| Name | Title | Task name/title | ✅ |
| Status | Select | Task status (Not Started, In Progress, Blocked, Completed, Escalated) | ✅ |
| Priority | Select | Priority level (Low, Medium, High, Critical) | ✅ |
| Type | Select | Task type (Feature, Bug, Documentation, Notification) | ✅ |
| Assignee | Person | Person assigned to the task | ❌ |
| Due Date | Date | Task due date | ❌ |
| Description | Rich Text | Detailed task description | ❌ |
| Blocked Since | Date | When the task was blocked (auto-set) | ❌ |
| Escalation Date | Date | When the task was escalated (auto-set) | ❌ |
| Dependencies | Relation | Related tasks that must be completed first | ❌ |
| Materials | Relation | Related materials | ❌ |
| Tags | Multi-select | Task tags/categories | ❌ |

## 📚 Materials Database

**Database ID**: `NOTION_DATABASE_ID_MATERIALS`

| Property Name | Type | Description | Required |
|---------------|------|-------------|----------|
| Name | Title | Material name/title | ✅ |
| Status | Select | Material status (Locked, Available, Archived) | ✅ |
| Type | Select | Material type (Document, Video, Code, Template) | ✅ |
| Category | Select | Material category | ❌ |
| Description | Rich Text | Material description | ❌ |
| URL | URL | Link to the material | ❌ |
| Required Tasks | Relation | Tasks that must be completed to unlock | ❌ |
| Unlocked Date | Date | When the material was unlocked (auto-set) | ❌ |
| Unlocked By | Select | Who unlocked it (User, System) | ❌ |
| Access Level | Select | Access level (Public, Team, Restricted) | ❌ |
| Tags | Multi-select | Material tags | ❌ |

## ⚠️ Risks Database

**Database ID**: `NOTION_DATABASE_ID_RISKS`

| Property Name | Type | Description | Required |
|---------------|------|-------------|----------|
| Title | Title | Risk title | ✅ |
| Risk Type | Select | Type of risk (Task Blockage, Resource Shortage, Technical Debt, Security) | ✅ |
| Severity | Select | Risk severity (Low, Medium, High, Critical) | ✅ |
| Status | Select | Risk status (Identified, Mitigated, Closed, Escalated) | ✅ |
| Description | Rich Text | Detailed risk description | ❌ |
| Impact | Rich Text | Potential impact description | ❌ |
| Mitigation | Rich Text | Mitigation strategy | ❌ |
| Assigned To | Person | Person responsible for risk management | ❌ |
| Identified Date | Date | When the risk was identified | ❌ |
| Due Date | Date | Risk resolution due date | ❌ |
| Related Tasks | Relation | Related tasks | ❌ |
| Related Materials | Relation | Related materials | ❌ |

## 👥 Team Database

**Database ID**: `NOTION_DATABASE_ID_TEAM`

| Property Name | Type | Description | Required |
|---------------|------|-------------|----------|
| Name | Title | Team member name | ✅ |
| Role | Select | Team member role (Developer, Designer, Manager, QA) | ✅ |
| Status | Select | Status (Active, Inactive, On Leave) | ✅ |
| Email | Email | Team member email | ❌ |
| Department | Select | Department/team | ❌ |
| Skills | Multi-select | Skills and competencies | ❌ |
| Availability | Select | Availability status (Available, Busy, Unavailable) | ❌ |
| Current Tasks | Relation | Currently assigned tasks | ❌ |
| Manager | Person | Direct manager | ❌ |
| Hire Date | Date | When they joined the team | ❌ |

## 🔄 Workflow Triggers

### Task Escalation Workflow
- **Trigger**: Hourly schedule
- **Condition**: Tasks with status "Blocked" for more than 1 week
- **Action**: 
  - Update task status to "Escalated"
  - Set priority to "High"
  - Create risk entry

### Materials Unlock Workflow
- **Trigger**: Every 5 minutes
- **Condition**: Materials with status "Locked" and all required tasks completed
- **Action**:
  - Update material status to "Available"
  - Create notification task

## 📝 Usage Notes

1. **Select Options**: All select fields have predefined options that should be used consistently
2. **Relations**: Use relation fields to create connections between databases
3. **Auto-fields**: Fields marked as "auto-set" are managed by workflows
4. **Required Fields**: Required fields must be filled when creating new entries
5. **Permissions**: Ensure proper Notion integration permissions for all databases

## 🔧 Configuration

To use these mappings:

1. Create the databases in Notion with the exact property names
2. Set up the select options as specified
3. Configure the relation fields between databases
4. Update the environment variables with your database IDs
5. Import the n8n workflows from `config/n8n/flows/`
