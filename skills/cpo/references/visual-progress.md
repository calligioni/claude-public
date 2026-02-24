# Visual Progress Tracking

Reference document for displaying CPO workflow progress in terminal and browser formats.

---

## 1. Terminal Progress Display

### Full Progress Dashboard

Display comprehensive progress information with ASCII art formatting:

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   CPO PROGRESS: taskflow                                                     ║
║   ══════════════════════════════════════════════════════════════════════     ║
║                                                                              ║
║   Phase 3 of 5: EXECUTION                                                    ║
║   ┌────────────────────────────────────────────────────────────────────┐     ║
║   │████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░│ 50% (6/12 stages) │     ║
║   └────────────────────────────────────────────────────────────────────┘     ║
║                                                                              ║
║   Stages Overview:                                                           ║
║   ┌──────────────────────────────┬──────────────────────────────┐            ║
║   │ [✓] S1   Foundation          │ [✓] S7   User Dashboard      │            ║
║   │ [✓] S2   Authentication      │ [→] S8   Task Management     │ ← Current  ║
║   │ [✓] S3   Database Schema     │ [ ] S9   Notifications       │            ║
║   │ [✓] S4   API Endpoints       │ [ ] S10  Settings            │            ║
║   │ [✓] S5   Core Components     │ [ ] S11  Testing             │            ║
║   │ [✓] S6   Navigation          │ [ ] S12  Documentation       │            ║
║   └──────────────────────────────┴──────────────────────────────┘            ║
║                                                                              ║
║   Current: S8 - Task Management                                              ║
║   Story:   3/5 - Implementing drag-and-drop reordering                       ║
║   Status:  IN PROGRESS                                                       ║
║                                                                              ║
║   ─────────────────────────────────────────────────────────────────────      ║
║   Started: 2024-01-15 09:30 | Elapsed: 2h 45m | ETA: ~3h remaining           ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### Minimal Box Progress

For environments with limited Unicode support:

```
+==============================================================================+
|  CPO PROGRESS: taskflow                                                      |
|  ========================================================================    |
|                                                                              |
|  Phase: Execution (3/5)                                                      |
|  [########............] 50% complete                                         |
|                                                                              |
|  Stages:                                                                     |
|  [X] S1  Foundation         |  [X] S7  User Dashboard                        |
|  [X] S2  Authentication     |  [>] S8  Task Management    <- CURRENT         |
|  [X] S3  Database Schema    |  [ ] S9  Notifications                         |
|  [X] S4  API Endpoints      |  [ ] S10 Settings                              |
|  [X] S5  Core Components    |  [ ] S11 Testing                               |
|  [X] S6  Navigation         |  [ ] S12 Documentation                         |
|                                                                              |
|  Current Story: 3/5 - Drag-and-drop reordering                               |
+==============================================================================+
```

---

## 2. Compact Progress Line

For continuous display during execution:

### Standard Compact

```
[████████░░░░] 8/12 stages | S8: Task Management | Story 3/5 | No blockers
```

### With Time Information

```
[████████░░░░] 67% | Stage 8/12 | Story 3/5 | Elapsed: 2h 15m | ETA: 1h 30m
```

### With Status Indicator

```
CPO [████████░░░░] 8/12 ● S8:TaskMgmt (3/5) ● OK ● 2h elapsed
```

### Error State

```
CPO [████████░░░░] 8/12 ● S8:TaskMgmt (3/5) ● BLOCKED ● Test failure
```

---

## 3. Phase Progress Indicators

### Linear Phase Display

```
Phases:
[✓] Discovery  ─→  [✓] Planning  ─→  [→] Execution  ─→  [ ] Validation  ─→  [ ] Delivery
     100%               100%              50%              0%                 0%
```

### Vertical Phase Display

```
Phase Progress
══════════════
 ✓  1. Discovery     ████████████████████  100%
 ✓  2. Planning      ████████████████████  100%
 →  3. Execution     ██████████░░░░░░░░░░   50%
    4. Validation    ░░░░░░░░░░░░░░░░░░░░    0%
    5. Delivery      ░░░░░░░░░░░░░░░░░░░░    0%
```

### Phase Timeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE TIMELINE                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Discovery    Planning     Execution       Validation    Delivery          │
│  ████████     ████████     ████░░░░░░░░    ░░░░░░░░      ░░░░░░░░          │
│     ✓            ✓            →               ○             ○              │
│  (15 min)     (30 min)      (2h 45m)                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Progress Generation Functions

### Core Progress Bar Generator

```javascript
/**
 * Generate an ASCII progress bar
 * @param {number} current - Current progress value
 * @param {number} total - Total value for 100%
 * @param {number} width - Character width of the bar
 * @param {object} options - Customization options
 * @returns {string} ASCII progress bar
 */
function generateProgressBar(current, total, width = 20, options = {}) {
  const {
    filledChar = '█',
    emptyChar = '░',
    showPercent = true,
    showCount = true
  } = options;

  const percent = Math.min(100, Math.round((current / total) * 100));
  const filled = Math.round((current / total) * width);
  const empty = width - filled;

  let bar = filledChar.repeat(filled) + emptyChar.repeat(empty);

  if (showPercent || showCount) {
    bar += ' ';
    if (showPercent) bar += `${percent}%`;
    if (showPercent && showCount) bar += ' ';
    if (showCount) bar += `(${current}/${total})`;
  }

  return bar;
}
```

### Stage Grid Generator

```javascript
/**
 * Generate a two-column stage grid display
 * @param {Array} stages - Array of stage objects
 * @returns {string} Formatted stage grid
 */
function generateStageGrid(stages) {
  const half = Math.ceil(stages.length / 2);
  const left = stages.slice(0, half);
  const right = stages.slice(half);

  const lines = left.map((l, i) => {
    const r = right[i] || { id: '', name: '', status: 'pending' };
    const lIcon = getStatusIcon(l.status);
    const rIcon = r.id ? getStatusIcon(r.status) : ' ';
    const lId = l.id.padEnd(4);
    const rId = r.id ? r.id.padEnd(4) : '    ';
    const lName = l.name.padEnd(18);
    const rName = (r.name || '').padEnd(18);

    let line = `[${lIcon}] ${lId} ${lName} │ [${rIcon}] ${rId} ${rName}`;

    if (l.status === 'in_progress') {
      line += ' ← Current';
    } else if (r.status === 'in_progress') {
      line += ' ← Current';
    }

    return line;
  });

  return lines.join('\n');
}
```

### Status Icon Mapper

```javascript
/**
 * Get status icon for a given status
 * @param {string} status - Status string
 * @returns {string} Status icon character
 */
function getStatusIcon(status) {
  const icons = {
    'tested': '✓',
    'complete': '✓',
    'passed': '✓',
    'in_progress': '→',
    'current': '→',
    'running': '→',
    'failed': '✗',
    'error': '✗',
    'blocked': '!',
    'skipped': '⊘',
    'pending': ' ',
    'waiting': ' '
  };

  return icons[status] || ' ';
}

/**
 * ASCII-safe status icons (no Unicode)
 */
function getStatusIconAscii(status) {
  const icons = {
    'tested': 'X',
    'complete': 'X',
    'passed': 'X',
    'in_progress': '>',
    'current': '>',
    'running': '>',
    'failed': '!',
    'error': '!',
    'blocked': '#',
    'skipped': '-',
    'pending': ' ',
    'waiting': ' '
  };

  return icons[status] || ' ';
}
```

### Full Dashboard Generator

```javascript
/**
 * Generate complete progress dashboard
 * @param {object} project - Master project object
 * @returns {string} Complete ASCII dashboard
 */
function generateDashboard(project) {
  const { name, currentPhase, stages, currentStage, currentStory } = project;

  const completedStages = stages.filter(s => s.status === 'tested').length;
  const totalStages = stages.length;
  const progressBar = generateProgressBar(completedStages, totalStages, 48);
  const stageGrid = generateStageGrid(stages);
  const phaseIndicator = generatePhaseIndicator(currentPhase);

  const width = 78;
  const border = '═'.repeat(width);

  return `
╔${'═'.repeat(width)}╗
║${' '.repeat(width)}║
║   CPO PROGRESS: ${name.padEnd(width - 18)}║
║   ${border.slice(0, width - 6)}   ║
║${' '.repeat(width)}║
║   Phase ${currentPhase} of 5: ${getPhaseLabel(currentPhase).toUpperCase().padEnd(width - 20)}║
║   ┌${'─'.repeat(width - 8)}┐   ║
║   │${progressBar.padEnd(width - 10)}│   ║
║   └${'─'.repeat(width - 8)}┘   ║
║${' '.repeat(width)}║
║   Stages Overview:${' '.repeat(width - 20)}║
${formatGridInBox(stageGrid, width)}
║${' '.repeat(width)}║
║   Current: ${currentStage.id} - ${currentStage.name.padEnd(width - 16 - currentStage.id.length)}║
║   Story:   ${currentStory.number}/${currentStage.totalStories} - ${currentStory.title.substring(0, width - 22).padEnd(width - 16)}║
║   Status:  ${currentStory.status.toUpperCase().padEnd(width - 13)}║
║${' '.repeat(width)}║
╚${'═'.repeat(width)}╝
`;
}
```

### Phase Label Helper

```javascript
/**
 * Get human-readable phase label
 * @param {number} phase - Phase number (1-5)
 * @returns {string} Phase label
 */
function getPhaseLabel(phase) {
  const labels = {
    1: 'Discovery',
    2: 'Planning',
    3: 'Execution',
    4: 'Validation',
    5: 'Delivery'
  };
  return labels[phase] || 'Unknown';
}
```

---

## 5. HTML Progress Dashboard

### Generate progress.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CPO Progress: {project}</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: 'SF Mono', 'Fira Code', 'Consolas', monospace;
      background: linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%);
      color: #e2e8f0;
      min-height: 100vh;
      padding: 2rem;
    }

    .container {
      max-width: 900px;
      margin: 0 auto;
    }

    h1 {
      font-size: 2rem;
      margin-bottom: 0.5rem;
      background: linear-gradient(90deg, #6366f1, #a855f7);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .subtitle {
      color: #94a3b8;
      margin-bottom: 2rem;
    }

    .phase-bar {
      display: flex;
      gap: 1rem;
      margin-bottom: 2rem;
    }

    .phase {
      flex: 1;
      text-align: center;
      padding: 0.75rem;
      background: #1e293b;
      border-radius: 8px;
      position: relative;
    }

    .phase.complete {
      background: linear-gradient(135deg, #065f46, #047857);
    }

    .phase.current {
      background: linear-gradient(135deg, #4338ca, #6366f1);
      box-shadow: 0 0 20px rgba(99, 102, 241, 0.4);
    }

    .phase-number {
      font-size: 0.75rem;
      opacity: 0.7;
    }

    .phase-name {
      font-weight: bold;
    }

    .progress-section {
      background: #1e293b;
      border-radius: 12px;
      padding: 1.5rem;
      margin-bottom: 2rem;
    }

    .progress-header {
      display: flex;
      justify-content: space-between;
      margin-bottom: 1rem;
    }

    .progress-bar {
      background: #0f172a;
      border-radius: 12px;
      height: 32px;
      overflow: hidden;
      position: relative;
    }

    .progress-fill {
      background: linear-gradient(90deg, #6366f1, #8b5cf6, #a855f7);
      height: 100%;
      border-radius: 12px;
      transition: width 0.5s ease-out;
      position: relative;
    }

    .progress-fill::after {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: linear-gradient(
        90deg,
        transparent 0%,
        rgba(255,255,255,0.2) 50%,
        transparent 100%
      );
      animation: shimmer 2s infinite;
    }

    @keyframes shimmer {
      0% { transform: translateX(-100%); }
      100% { transform: translateX(100%); }
    }

    .stages-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 1rem;
    }

    .stage {
      display: flex;
      align-items: center;
      padding: 1rem;
      background: #1e293b;
      border-radius: 8px;
      border-left: 4px solid #475569;
      transition: all 0.2s ease;
    }

    .stage:hover {
      transform: translateX(4px);
      background: #334155;
    }

    .stage.complete {
      border-left-color: #22c55e;
    }

    .stage.current {
      border-left-color: #6366f1;
      background: linear-gradient(90deg, rgba(99, 102, 241, 0.1), transparent);
    }

    .stage.failed {
      border-left-color: #ef4444;
    }

    .stage-icon {
      width: 24px;
      height: 24px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 1rem;
      font-size: 0.875rem;
    }

    .stage.complete .stage-icon {
      background: #22c55e;
      color: #0f172a;
    }

    .stage.current .stage-icon {
      background: #6366f1;
      color: white;
      animation: pulse 2s infinite;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.6; }
    }

    .stage.pending .stage-icon {
      background: #475569;
    }

    .stage-id {
      font-weight: bold;
      margin-right: 0.5rem;
      color: #94a3b8;
    }

    .current-task {
      background: linear-gradient(135deg, #1e293b, #334155);
      border-radius: 12px;
      padding: 1.5rem;
      margin-top: 2rem;
      border: 1px solid #475569;
    }

    .current-label {
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 0.1em;
      color: #6366f1;
      margin-bottom: 0.5rem;
    }

    .current-stage-name {
      font-size: 1.5rem;
      font-weight: bold;
      margin-bottom: 0.5rem;
    }

    .current-story {
      color: #94a3b8;
    }

    .stats {
      display: flex;
      gap: 2rem;
      margin-top: 1.5rem;
    }

    .stat {
      text-align: center;
    }

    .stat-value {
      font-size: 2rem;
      font-weight: bold;
      background: linear-gradient(90deg, #6366f1, #a855f7);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .stat-label {
      font-size: 0.75rem;
      color: #94a3b8;
      text-transform: uppercase;
    }

    .footer {
      text-align: center;
      margin-top: 2rem;
      color: #475569;
      font-size: 0.875rem;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>{project}</h1>
    <p class="subtitle">CPO Progress Dashboard</p>

    <div class="phase-bar">
      <div class="phase complete">
        <div class="phase-number">Phase 1</div>
        <div class="phase-name">Discovery</div>
      </div>
      <div class="phase complete">
        <div class="phase-number">Phase 2</div>
        <div class="phase-name">Planning</div>
      </div>
      <div class="phase current">
        <div class="phase-number">Phase 3</div>
        <div class="phase-name">Execution</div>
      </div>
      <div class="phase">
        <div class="phase-number">Phase 4</div>
        <div class="phase-name">Validation</div>
      </div>
      <div class="phase">
        <div class="phase-number">Phase 5</div>
        <div class="phase-name">Delivery</div>
      </div>
    </div>

    <div class="progress-section">
      <div class="progress-header">
        <span>Stage Progress</span>
        <span>{percent}% ({complete}/{total} stages)</span>
      </div>
      <div class="progress-bar">
        <div class="progress-fill" style="width: {percent}%"></div>
      </div>
    </div>

    <div class="stages-grid">
      <!-- Stage entries generated dynamically -->
      <div class="stage complete">
        <div class="stage-icon">&#10003;</div>
        <span class="stage-id">S1</span>
        <span>Foundation</span>
      </div>
      <!-- More stages... -->
    </div>

    <div class="current-task">
      <div class="current-label">Currently Working On</div>
      <div class="current-stage-name">{current_stage}</div>
      <div class="current-story">Story {story_num}/{story_total}: {story_title}</div>

      <div class="stats">
        <div class="stat">
          <div class="stat-value">{elapsed}</div>
          <div class="stat-label">Elapsed Time</div>
        </div>
        <div class="stat">
          <div class="stat-value">{eta}</div>
          <div class="stat-label">Est. Remaining</div>
        </div>
        <div class="stat">
          <div class="stat-value">{stories_complete}</div>
          <div class="stat-label">Stories Done</div>
        </div>
      </div>
    </div>

    <div class="footer">
      Last updated: {timestamp} | Generated by CPO AI Skill
    </div>
  </div>

  <script>
    // Auto-refresh every 30 seconds
    setTimeout(() => location.reload(), 30000);
  </script>
</body>
</html>
```

### HTML Generator Function

```javascript
/**
 * Generate HTML progress dashboard
 * @param {object} project - Master project object
 * @param {string} outputPath - Path to write HTML file
 */
function generateProgressHtml(project, outputPath = 'progress.html') {
  const template = getHtmlTemplate();

  const completedStages = project.stages.filter(s => s.status === 'tested').length;
  const totalStages = project.stages.length;
  const percent = Math.round((completedStages / totalStages) * 100);

  const stagesHtml = project.stages.map(stage => {
    const statusClass = stage.status === 'tested' ? 'complete'
      : stage.status === 'in_progress' ? 'current'
      : stage.status === 'failed' ? 'failed'
      : 'pending';

    const icon = statusClass === 'complete' ? '&#10003;'
      : statusClass === 'current' ? '&#10148;'
      : statusClass === 'failed' ? '&#10007;'
      : '';

    return `
      <div class="stage ${statusClass}">
        <div class="stage-icon">${icon}</div>
        <span class="stage-id">${stage.id}</span>
        <span>${stage.name}</span>
      </div>
    `;
  }).join('\n');

  const html = template
    .replace(/{project}/g, project.name)
    .replace(/{percent}/g, percent)
    .replace(/{complete}/g, completedStages)
    .replace(/{total}/g, totalStages)
    .replace(/<!-- Stage entries.*?-->/s, stagesHtml)
    .replace(/{current_stage}/g, project.currentStage?.name || 'N/A')
    .replace(/{story_num}/g, project.currentStory?.number || 0)
    .replace(/{story_total}/g, project.currentStage?.totalStories || 0)
    .replace(/{story_title}/g, project.currentStory?.title || 'N/A')
    .replace(/{elapsed}/g, formatDuration(project.elapsedTime))
    .replace(/{eta}/g, formatDuration(project.estimatedRemaining))
    .replace(/{stories_complete}/g, project.completedStories || 0)
    .replace(/{timestamp}/g, new Date().toLocaleString());

  // Write to file system
  writeFileSync(outputPath, html);
}
```

---

## 6. Real-time Progress Updates

### Update Triggers

Progress display should be updated after these events:

```javascript
const PROGRESS_UPDATE_TRIGGERS = [
  'story_complete',
  'story_failed',
  'stage_complete',
  'stage_failed',
  'test_passed',
  'test_failed',
  'blocker_detected',
  'blocker_resolved',
  'phase_transition'
];
```

### Progress Update Handler

```javascript
/**
 * Handle progress updates
 * @param {string} event - Event type
 * @param {object} data - Event data
 * @param {object} project - Master project object
 */
function handleProgressUpdate(event, data, project) {
  // Update internal state
  updateProjectState(event, data, project);

  // Display based on configured mode
  const displayMode = project.progress?.displayMode || 'compact';

  switch (displayMode) {
    case 'full':
      console.clear();
      console.log(generateDashboard(project));
      break;
    case 'compact':
      console.log(generateCompactLine(project));
      break;
    case 'minimal':
      // Only show on stage transitions
      if (['stage_complete', 'phase_transition'].includes(event)) {
        console.log(generateCompactLine(project));
      }
      break;
  }

  // Generate HTML if configured
  if (project.progress?.generateHtml) {
    generateProgressHtml(project, project.progress.htmlPath);
  }
}
```

### Compact Line Generator

```javascript
/**
 * Generate compact single-line progress
 * @param {object} project - Master project object
 * @returns {string} Compact progress line
 */
function generateCompactLine(project) {
  const completed = project.stages.filter(s => s.status === 'tested').length;
  const total = project.stages.length;
  const bar = generateProgressBar(completed, total, 12, {
    showPercent: false,
    showCount: false
  });

  const stage = project.currentStage;
  const story = project.currentStory;
  const blockers = project.blockers?.length || 0;
  const blockerStatus = blockers > 0 ? `${blockers} blocker(s)` : 'No blockers';

  return `[${bar}] ${completed}/${total} stages | ${stage.id}: ${stage.name} | Story ${story.number}/${stage.totalStories} | ${blockerStatus}`;
}
```

---

## 7. Integration with CPO Workflow

### Add to Step 3.4 (Handle Results)

```javascript
// In the main CPO execution loop
async function executeStory(story, masterProject) {
  // ... story execution code ...

  // After story completion - update progress
  handleProgressUpdate('story_complete', { story }, masterProject);

  // Check if stage is complete
  if (isStageComplete(masterProject.currentStage)) {
    handleProgressUpdate('stage_complete', {
      stage: masterProject.currentStage
    }, masterProject);

    // Move to next stage
    advanceToNextStage(masterProject);
  }

  // Generate HTML if configured
  if (masterProject.progress?.generateHtml) {
    generateProgressHtml(masterProject, masterProject.progress.htmlPath);
  }
}

// After test completion
async function runStageTests(stage, masterProject) {
  const results = await runTests(stage);

  if (results.passed) {
    handleProgressUpdate('test_passed', { stage, results }, masterProject);
  } else {
    handleProgressUpdate('test_failed', { stage, results }, masterProject);
  }

  return results;
}
```

### Progress Display Wrapper

```javascript
/**
 * Display progress with animation effect
 * @param {object} project - Master project object
 */
function displayProgress(project) {
  const displayMode = project.progress?.displayMode || 'compact';

  switch (displayMode) {
    case 'full':
      // Clear screen and show full dashboard
      console.log('\x1b[2J\x1b[H'); // Clear terminal
      console.log(generateDashboard(project));
      break;

    case 'compact':
      // Single line update
      process.stdout.write('\r' + generateCompactLine(project));
      break;

    case 'minimal':
      // Status only on significant events
      console.log(`[CPO] ${project.currentStage.id} - ${project.currentStory.title}`);
      break;
  }
}
```

---

## 8. master-project.json Progress Config

### Configuration Schema

```json
{
  "name": "taskflow",
  "progress": {
    "displayMode": "compact",
    "generateHtml": true,
    "htmlPath": "progress.html",
    "refreshInterval": 30000,
    "showTimestamps": true,
    "showEstimates": true,
    "notifyOnComplete": true,
    "animations": true
  }
}
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `displayMode` | string | "compact" | Display mode: "full", "compact", or "minimal" |
| `generateHtml` | boolean | false | Generate HTML progress dashboard |
| `htmlPath` | string | "progress.html" | Path for HTML file output |
| `refreshInterval` | number | 30000 | HTML auto-refresh interval in ms |
| `showTimestamps` | boolean | true | Show timestamps in progress display |
| `showEstimates` | boolean | true | Show time estimates |
| `notifyOnComplete` | boolean | true | System notification on completion |
| `animations` | boolean | true | Enable terminal animations |

### Display Mode Examples

**Full Mode**: Complete dashboard with stage grid (best for dedicated terminal)

**Compact Mode**: Single-line updates (best for development)

**Minimal Mode**: Only major milestone updates (best for background execution)

---

## 9. Status Command Output

### User Types "status"

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  CPO STATUS: taskflow                                                        ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  Phase:      Execution (3/5)                                                 ║
║  Progress:   50% (6/12 stages complete)                                      ║
║  Current:    S8 - Task Management                                            ║
║                                                                              ║
║  ┌─────────────────────────────────────────────────────────────────────┐     ║
║  │████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░│ 50%                │     ║
║  └─────────────────────────────────────────────────────────────────────┘     ║
║                                                                              ║
║  RECENT ACTIVITY                                                             ║
║  ──────────────────                                                          ║
║  [✓] S7 - User Dashboard       completed    2 min ago                        ║
║  [✓] S6 - Navigation           completed   15 min ago                        ║
║  [✓] S5 - Core Components      completed   28 min ago                        ║
║                                                                              ║
║  COMING UP NEXT                                                              ║
║  ──────────────────                                                          ║
║  [ ] S9  - Notifications       4 stories   ~25 min                           ║
║  [ ] S10 - Settings            3 stories   ~20 min                           ║
║  [ ] S11 - Testing             5 stories   ~35 min                           ║
║                                                                              ║
║  BLOCKERS: None                                                              ║
║                                                                              ║
║  ──────────────────────────────────────────────────────────────────────      ║
║  Started: 09:30 | Elapsed: 2h 45m | ETA: ~3h remaining                       ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### Status Generator Function

```javascript
/**
 * Generate status command output
 * @param {object} project - Master project object
 * @returns {string} Formatted status output
 */
function generateStatusOutput(project) {
  const completed = project.stages.filter(s => s.status === 'tested');
  const pending = project.stages.filter(s => s.status === 'pending');
  const current = project.currentStage;

  const recentActivity = completed
    .slice(-3)
    .reverse()
    .map(s => `[✓] ${s.id} - ${s.name.padEnd(20)} completed ${formatTimeAgo(s.completedAt)}`);

  const upNext = pending
    .slice(0, 3)
    .map(s => `[ ] ${s.id.padEnd(4)} - ${s.name.padEnd(20)} ${s.stories.length} stories   ~${estimateTime(s)}`);

  const blockers = project.blockers || [];
  const blockerText = blockers.length === 0
    ? 'None'
    : blockers.map(b => `[!] ${b.description}`).join('\n  ');

  return `
## CPO Status: ${project.name}

Phase: ${getPhaseLabel(project.currentPhase)} (${project.currentPhase}/5)
Progress: ${Math.round((completed.length / project.stages.length) * 100)}% (${completed.length}/${project.stages.length} stages)
Current: ${current.id} - ${current.name}

Recent:
${recentActivity.map(a => `- ${a}`).join('\n')}

Next up:
${upNext.map(u => `- ${u}`).join('\n')}

Blockers: ${blockerText}
`;
}
```

### Time Formatting Helpers

```javascript
/**
 * Format duration in human-readable form
 * @param {number} ms - Duration in milliseconds
 * @returns {string} Formatted duration
 */
function formatDuration(ms) {
  if (!ms) return 'N/A';

  const hours = Math.floor(ms / 3600000);
  const minutes = Math.floor((ms % 3600000) / 60000);

  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  }
  return `${minutes}m`;
}

/**
 * Format time ago
 * @param {Date} timestamp - Past timestamp
 * @returns {string} Relative time string
 */
function formatTimeAgo(timestamp) {
  if (!timestamp) return '';

  const now = Date.now();
  const diff = now - new Date(timestamp).getTime();
  const minutes = Math.floor(diff / 60000);

  if (minutes < 1) return 'just now';
  if (minutes === 1) return '1 min ago';
  if (minutes < 60) return `${minutes} min ago`;

  const hours = Math.floor(minutes / 60);
  if (hours === 1) return '1 hour ago';
  return `${hours} hours ago`;
}
```

---

## 10. Additional Visual Elements

### Stage Detail View

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  STAGE S8: Task Management                                                   │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Stories:                                                                    │
│  ────────                                                                    │
│  [✓] 1. Create task list component                      completed           │
│  [✓] 2. Add task creation modal                         completed           │
│  [→] 3. Implement drag-and-drop reordering              in progress         │
│  [ ] 4. Add task filtering and search                   pending             │
│  [ ] 5. Implement task completion flow                  pending             │
│                                                                              │
│  Progress: [████████████░░░░░░░░] 60% (3/5 stories)                          │
│                                                                              │
│  Tests:                                                                      │
│  ────────                                                                    │
│  [✓] Unit tests:        12/12 passed                                         │
│  [→] Integration tests: Running...                                           │
│  [ ] E2E tests:         Pending                                              │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Error/Blocker Display

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ⚠  BLOCKER DETECTED                                                         ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  Stage:   S8 - Task Management                                               ║
║  Story:   3 - Implement drag-and-drop reordering                             ║
║                                                                              ║
║  Error:   Test failure in TaskList.test.tsx                                  ║
║  ────────────────────────────────────────────────────────────────────────    ║
║  Expected: items to be reordered after drag                                  ║
║  Received: items unchanged                                                   ║
║                                                                              ║
║  File: src/components/TaskList/TaskList.test.tsx:45                          ║
║                                                                              ║
║  Suggested Actions:                                                          ║
║  - Check onDragEnd handler implementation                                    ║
║  - Verify state update logic                                                 ║
║  - Review DnD library event handling                                         ║
║                                                                              ║
║  [R]etry  [S]kip  [M]anual fix  [A]bort                                      ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### Completion Celebration

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                           PROJECT COMPLETE                                   ║
║                                                                              ║
║      ████████████████████████████████████████████████████████████████        ║
║      ████████████████████████████████████████████████████████████████        ║
║                                                                              ║
║                          taskflow                                            ║
║                                                                              ║
║      Total Stages:     12                                                    ║
║      Total Stories:    47                                                    ║
║      Tests Passed:     156                                                   ║
║      Total Time:       5h 32m                                                ║
║                                                                              ║
║      ──────────────────────────────────────────────────────────────          ║
║                                                                              ║
║      Deliverables:                                                           ║
║      - /output/taskflow-bundle.zip                                           ║
║      - /docs/README.md                                                       ║
║      - /docs/API.md                                                          ║
║                                                                              ║
║      Phase 5: Delivery - COMPLETE                                            ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## Summary

This reference provides comprehensive visual progress tracking for the CPO workflow:

1. **Full Dashboard**: Detailed ASCII art display for dedicated monitoring
2. **Compact Line**: Single-line updates for development workflow
3. **Phase Indicators**: Clear visibility of overall progress
4. **JavaScript Functions**: Ready-to-use generators for all display types
5. **HTML Dashboard**: Browser-based visual tracking with auto-refresh
6. **Real-time Updates**: Event-driven progress refresh
7. **Configuration**: Flexible options in master-project.json
8. **Status Command**: Quick status check with recent activity
9. **Error Display**: Clear blocker and error visualization
10. **Completion View**: Celebratory project completion display

Use the display mode that best fits your workflow and environment.
