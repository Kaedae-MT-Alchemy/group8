# MT Alchemy: final update

**Date:** 19 November 2026 · **Live site:** https://sayyadsuzain9001.github.io/MT-Alchemy/ · **Mirror:** https://kaedae-mt-alchemy.github.io/group8/

This document summarises the last round of work on the platform: what changed, where to find it, and how it was tested.

> [!IMPORTANT]
> **At a glance**
> - 8 courses × 16 lessons = **128 lessons**, plus **64 quiz questions**.
> - Admins can now **build courses** (lessons, uploads, quizzes) and **edit the whole website** without code.
> - Every order has a **PDF invoice / receipt**.
> - **101 automated tests pass**, `flutter analyze` is clean, and every feature was rechecked on the live site.

---

## 1. Course content, lessons and quizzes

### What learners get

| Per course | Content |
| --- | --- |
| 5 modules | Each with its own topic, e.g. *Leadership Essentials → Foundations of Leadership, Leading Yourself, Leading Teams, Decision-Making, Creating High-Performing Teams* |
| 16 lessons | 1 welcome video (MP4) + per module: a TED/YouTube talk, reading notes (summary, key ideas, practice task) and one resource |
| Resources | Course slides (PPTX), learner workbook (PDF), reflection worksheet (DOCX), further-reading article, action plan (PDF) |
| Quiz | 8 questions: multiple choice, select all that apply, true/false and short answer, each with an explanation |

Every lesson is different: the 40 module videos use 32 different TED, TEDx and YouTube talks, each checked to exist, and every reading is written for its module.

### Course player

- Sidebar lists every lesson with its type and length, and ticks completed lessons.
- **Video:** YouTube plays inline; MP4 files play in a built-in player.
- **PDF:** shown inline in the browser's PDF viewer.
- **Slides / documents:** shown inline with Microsoft's Office viewer, plus Download.
- **Reading:** formatted notes with bullet points.
- Open in a new tab and Download buttons on every file lesson.
- Progress and certificates count each course's real lessons.

### Lessons & quiz builder (admins and trainers)

Admin portal → Courses → **Lessons & quiz**:

- Add, rename, reorder and delete **modules**.
- Add, edit, reorder and delete **lessons** of any type.
- **Upload** PDF, PPT/PPTX/ODP, DOC/DOCX/ODT/RTF/TXT or MP4/WebM files up to 10 MB, or **paste a link** (YouTube, MP4, PDF, Office file or any web page).
- Build **quiz questions** of all four types, with explanations, and set the **pass mark**.
- Files no longer used are deleted when the course is saved.

> [!TIP]
> For videos longer than a few minutes, upload them to YouTube (unlisted is fine) and paste the link. Uploads are best for short clips and documents.

### Compatibility

Courses already in the database keep working: a course with no saved lessons uses the built-in content, and quizzes saved in the older format are read automatically.

## 2. Editable website (super admin)

- **Edit this page** on any public page shows **Change image** on every photo and a pencil on every text.
- Photos can be picked from the library, uploaded (compressed automatically) or linked.
- **Reset to original** undoes a change.
- Changes are live for every visitor immediately and are listed under Admin portal → **Website content**.

## 3. Programme pages

Each of the six corporate programmes has its own page at `/programme/<name>` with an intro, outcomes, who it is for, and links to enquire or browse related courses. **Explore programme** on the home page and **View programme** on the Services page open it in one click.

## 4. Invoices and receipts

- Branded A4 PDF: logo, contact details, bill-to and ship-to, item table (course, digital or physical), subtotal, shipping, total in RM, payment method and reference, and a thank-you note.
- **Invoice** (`INV-<order>`) while unpaid, **Receipt** (`RCT-<order>`) once paid, with a status badge.
- **Download** and **Print** on the order confirmation, order details, My Orders and admin Orders pages.

## 5. Design

- New wordmark: **MT Alchemy** in Fraunces with *Made to Thrive* in italic, across the header, phone menu and footer.

## 6. Data and security

| Collection | New or changed | Access |
| --- | --- | --- |
| `courses` | Now stores `lessons` and richer `quiz` questions | Public read; admin and trainer write |
| `lessonFiles` (+ `chunks`) | **New:** uploaded lesson files in 900 KB chunks | Signed-in read; admin and trainer write |
| `siteContent`, `siteImages`, `sitePages` | Website text and photo changes | Public read; admin write |

> [!WARNING]
> After pulling these changes into another Firebase project, deploy the rules once:
> `firebase deploy --only firestore:rules --project <project-id>`. Without them, lesson uploads are refused.

## 7. Testing

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues |
| `flutter test` | **101 passing** (course model and fallback, quiz scoring, chunked uploads, builder, invoices, site editing, all earlier tests) |
| GitHub Actions "Test and deploy" | Passed on both repositories |
| Live recheck | Programme links, every role's pages, enrolment with bank transfer and admin approval, every lesson type, uploads of PDF/MP4/PPTX, quiz scoring for all four question types, certificate and public verification, store orders with stock, employer invite/assign/reports, contact form, Stripe test checkout redirect, website editing and reset, invoice download and print |

## 8. Key files

| Path | Purpose |
| --- | --- |
| `lib/data/course_content.dart` | Lesson and quiz model, scoring, validation |
| `lib/data/lesson_files.dart` | Chunked file storage for uploads |
| `lib/admin/course_builder.dart` | Lessons & quiz builder |
| `lib/widgets/lms/lesson_viewer.dart` | Course player for every lesson type |
| `lib/commerce/invoice_pdf.dart` | Invoice / receipt PDF and buttons |
| `lib/programme_detail.dart` | Programme pages |
| `lib/cms/` | On-page website editing |
| `tool/course_content/` | Course content and the sample-file generator |
| `assets/materials/` | Generated PDF, PPTX, DOCX and MP4 files |

---

<sub>Prepared by <b>Sayyad</b></sub>
