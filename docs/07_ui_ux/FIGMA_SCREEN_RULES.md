# Figma Screen Creation Rules (MANDATORY)

> **Scope:** These rules apply to EVERY `use_figma` call that creates or modifies a screen in `Hexbound-Design` (fileKey: `PalemJ36B97ZdC0cd8jzv4`).
> **Violation = delete and rebuild.** No exceptions, no "fix later".

---

## Rule 0: READ SWIFT CODE FIRST

Before creating ANY screen in Figma:
1. Open the Swift source file (`*View.swift` or `*DetailView.swift`)
2. Read EVERY line — extract: texts, colors, fonts, spacing, components used
3. Create a **truth table** mapping Swift → Figma:
   - Every `Text("...")` → exact string to use
   - Every `.font(DarkFantasyTheme.X)` → Text Style to bind
   - Every `.foregroundStyle(DarkFantasyTheme.X)` → Color variable to bind
   - Every `.background(DarkFantasyTheme.X)` → Fill variable to bind
   - Every `.padding(.horizontal, LayoutConstants.X)` → Spacing variable to bind
   - Every `ScreenLayout`, `OrnamentalTitle`, `TabSwitcher`, `Card`, `Button` → DS component to import

**NEVER guess content.** If Swift says `Text("SESSION COMPLETE")`, Figma must say "SESSION COMPLETE", not "ARENA OF CHAMPIONS".

---

## Rule 1: ZERO Hardcoded Colors

**Every fill, stroke, and text color MUST be bound to a Color collection variable.**

### How to bind fills (MANDATORY code pattern):

```javascript
// ✅ CORRECT — bind to variable
const colorVar = await figma.variables.getVariableByIdAsync('VariableID:5:4'); // color/bg/primary
frame.setBoundVariable('fills', 0, colorVar.id);

// Before binding, set a placeholder fill first:
frame.fills = [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 } }];
frame.setBoundVariable('fills', 0, colorVar.id);
```

```javascript
// ❌ WRONG — hardcoded color
frame.fills = [{ type: 'SOLID', color: { r: 0.059, g: 0.055, b: 0.098 } }];
```

### Common Color Variable IDs (Screens file uses published library — use importVariableByKeyAsync or resolve from local):

| Swift Token | Figma Variable | Variable ID (DS file) |
|---|---|---|
| `DarkFantasyTheme.bgPrimary` | `color/bg/primary` | `VariableID:5:4` |
| `DarkFantasyTheme.bgSecondary` | `color/bg/secondary` | `VariableID:5:5` |
| `DarkFantasyTheme.bgTertiary` | `color/bg/tertiary` | `VariableID:5:6` |
| `DarkFantasyTheme.bgElevated` | `color/bg/elevated` | `VariableID:5:7` |
| `DarkFantasyTheme.textPrimary` | `color/text/primary` | `VariableID:5:19` |
| `DarkFantasyTheme.textSecondary` | `color/text/secondary` | `VariableID:5:20` |
| `DarkFantasyTheme.textTertiary` | `color/text/tertiary` | `VariableID:5:21` |
| `DarkFantasyTheme.textDisabled` | `color/text/disabled` | `VariableID:5:22` |
| `DarkFantasyTheme.gold` | `color/gold/default` | `VariableID:5:10` |
| `DarkFantasyTheme.textOnGold` | `color/text/on-gold` | `VariableID:5:24` |
| `DarkFantasyTheme.textGold` | `color/text/gold` | `VariableID:5:23` |
| `DarkFantasyTheme.danger` | `color/feedback/danger` | `VariableID:5:13` |
| `DarkFantasyTheme.success` | `color/feedback/success` | `VariableID:5:14` |
| `DarkFantasyTheme.borderSubtle` | `color/border/subtle` | `VariableID:5:28` |
| `DarkFantasyTheme.borderGold` | `color/border/gold` | `VariableID:5:31` |
| `DarkFantasyTheme.bgModal` | `color/bg/modal` | `VariableID:223:11` |
| `DarkFantasyTheme.bgScrim` | `color/bg/scrim` | `VariableID:223:14` |

### In the Screens file (consuming published library):

The Screens file does NOT have local variables — it uses the published library. To bind:

```javascript
// Method 1: Find existing variable by collection
const collections = await figma.variables.getLocalVariableCollectionsAsync();
// If published library is enabled, variables are accessible

// Method 2: Import from library (preferred)
const libCollections = await figma.teamLibrary.getAvailableLibraryVariableCollectionsAsync();
const hexboundLib = libCollections.find(c => c.libraryName.includes('Hexbound'));
if (hexboundLib) {
  const variables = await figma.teamLibrary.getVariablesInLibraryCollectionAsync(hexboundLib.key);
  const bgPrimary = variables.find(v => v.name === 'color/bg/primary');
  if (bgPrimary) {
    const imported = await figma.variables.importVariableByKeyAsync(bgPrimary.key);
    frame.fills = [figma.variables.setBoundVariableForPaint({ type: 'SOLID', color: {r:0,g:0,b:0} }, 'color', imported)];
  }
}
```

**If variable binding fails for ANY reason → STOP and debug. Do NOT fall back to hardcoded values.**

---

## Rule 2: ZERO Unstyled Text

**Every TEXT node MUST have a `textStyleId` bound to a published Text Style.**

### How to apply text styles (MANDATORY code pattern):

```javascript
// ✅ CORRECT — import and apply text style from library
const text = figma.createText();
await figma.loadFontAsync({ family: 'Inter', style: 'Regular' }); // MUST load font first
text.characters = 'Actual text from Swift code';

// Import text style from DS library
const styles = await figma.teamLibrary.getAvailableLibraryTextStylesAsync();
// OR use known key:
const bodyStyle = await figma.importStyleByKeyAsync('fef6dd502465059c68ca8041a45afbee2ed690f1');
text.textStyleId = bodyStyle.id;
```

```javascript
// ❌ WRONG — manual font settings
text.fontSize = 14;
text.fontName = { family: 'Inter', style: 'Regular' };
// This creates UNSTYLED text — no connection to DS
```

### Text Style Keys (for `importStyleByKeyAsync`):

| Swift Token | Figma Style | Key |
|---|---|---|
| `DarkFantasyTheme.cinematicTitle` | `Heading/Cinematic Title` (40) | `9c11a0c58dae12b273c8a237e9b0b98450eaebf1` |
| `DarkFantasyTheme.title` | `Heading/Title` (28) | `ce245f83ac721aeb90db5258e80bedcfaa4e8cae` |
| `DarkFantasyTheme.section` | `Heading/Section` (22) | `460e0abe0ddacaefa8b6f698fb61f27a04af7759` |
| `DarkFantasyTheme.cardTitle` | `Heading/Card Title` (18) | `24f763b8b7ec47532b5c5f77d77375124f082210` |
| `DarkFantasyTheme.buttonLabel` | `Heading/Button Label` (18) | `197938eeaef9704d5ddf2e6efe8c6986d62b6b7f` |
| `DarkFantasyTheme.buttonLabelCompact` | `Heading/Button Label Compact` (16) | `e5461cffd767dc18fc4ea03d3d5fcf7bff1f289c` |
| `DarkFantasyTheme.body` | `Body/Body` (16) | `fef6dd502465059c68ca8041a45afbee2ed690f1` |
| `DarkFantasyTheme.uiLabel` | `Body/UI Label` (14) | `b147294861bbd172aee02c25d4dd88c13c3a6b80` |
| `DarkFantasyTheme.caption` | `Body/Caption` (12) | `1d94244a59a22997f3f590d3ad9209b702a7a71d` |
| `DarkFantasyTheme.badge` | `Body/Badge` (11 bold) | `71f8c0a0806a1197ef63e77a0a591a5bfeac5a95` |

### Effect Style Keys (for shadow application):

| Figma Style | Key |
|---|---|
| `Shadow/Card` | `492a984d82c5f4febf620e4ff807e01a21521209` |
| `Shadow/Modal` | `1452cba48fb12135a3e248ea91e548c38c64133e` |
| `Shadow/Gold Glow` | `765a5605d7606710559e71a6a24e473e70461c1c` |
| `Shadow/Danger Glow` | `35769d68a9327b01327c68baca2442868f16b19b` |

---

## Rule 3: ZERO Custom Frames Pretending to Be Components

**If a DS component exists for it — USE THE COMPONENT. Never recreate with frames.**

### Required workflow:

```javascript
// Step 1: Search for existing component
// Use search_design_system tool FIRST to find component keys

// Step 2: Import the specific VARIANT (not the component set)
const comp = await figma.importComponentByKeyAsync('VARIANT_KEY_HERE');
const instance = comp.createInstance();

// Step 3: Append to parent BEFORE setting layout
parentFrame.appendChild(instance);

// Step 4: Set fill container AFTER appending
instance.layoutSizingHorizontal = 'FILL';
```

### Common mistakes (ALL FORBIDDEN):

| Don't Do This | Do This Instead |
|---|---|
| Gold rectangle + text = "button" | Import Button variant from DS |
| Frame + border + inner text = "card" | Import Card variant from DS |
| Horizontal line = "divider" | Import Divider/Gold variant from DS |
| Circle + text = "badge" | Import appropriate Badge from DS |
| Frame with progress bar fills | Import Progress Bar variant from DS |
| Frame + avatar + text = "row" | Import InboxRow/LeaderboardRow from DS |

### Getting variant keys:

```javascript
// In DS file (uDjXIz7CdJxcEOI5jCBcjY):
const page = figma.root.children.find(p => p.name === 'Buttons');
await figma.setCurrentPageAsync(page);
const compSet = page.findOne(n => n.type === 'COMPONENT_SET' && n.name === 'Button');
for (const variant of compSet.children) {
  // variant.key is what you use in importComponentByKeyAsync
  console.log(`${variant.name} → key: ${variant.key}`);
}
```

---

## Rule 4: Spacing MUST Use Variables

**Every auto-layout gap, padding, and cornerRadius MUST be bound to Spacing collection variables.**

```javascript
// ✅ CORRECT
const spacingMd = await figma.variables.importVariableByKeyAsync('SPACING_MD_KEY');
frame.setBoundVariable('itemSpacing', spacingMd.id);
frame.setBoundVariable('paddingLeft', spacingMd.id);
frame.setBoundVariable('paddingRight', spacingMd.id);

// ❌ WRONG
frame.itemSpacing = 16;
frame.paddingLeft = 16;
```

### Spacing Variable IDs (DS file):

| Token | Variable | ID |
|---|---|---|
| `LayoutConstants.space2XS` (2) | `spacing/2xs` | `VariableID:4:3` |
| `LayoutConstants.spaceXS` (4) | `spacing/xs` | `VariableID:4:4` |
| `LayoutConstants.spaceSM` (8) | `spacing/sm` | `VariableID:4:5` |
| `LayoutConstants.spaceMS` (12) | `spacing/ms` | `VariableID:4:6` |
| `LayoutConstants.spaceMD` (16) | `spacing/md` | `VariableID:4:7` |
| `LayoutConstants.spaceLG` (24) | `spacing/lg` | `VariableID:4:8` |
| `LayoutConstants.spaceXL` (32) | `spacing/xl` | `VariableID:4:9` |
| `LayoutConstants.space2XL` (48) | `spacing/2xl` | `VariableID:4:10` |

---

## Rule 5: Screen Frame Standard

Every screen frame MUST follow this template:

```javascript
const screen = figma.createFrame();
screen.name = 'Screen Name — from Swift class name';
screen.resize(390, 844);
screen.layoutMode = 'VERTICAL';
screen.primaryAxisAlignItems = 'MIN';
screen.counterAxisAlignItems = 'CENTER';
screen.clipsContent = true;

// Background: bind to color/bg/primary (NOT hardcode rgb(15,14,25))
screen.fills = [{ type: 'SOLID', color: {r:0,g:0,b:0} }];
// Then bind: screen.setBoundVariable('fills', 0, bgPrimaryVar.id);

// Status bar padding
screen.paddingTop = 60;
screen.paddingBottom = 0;
screen.paddingLeft = 0;
screen.paddingRight = 0;
screen.itemSpacing = 0; // components handle their own spacing
```

---

## Rule 6: Text Content MUST Match Swift Code

| Swift Code | Figma Text Content |
|---|---|
| `OrnamentalTitle("Tutorial")` | Override OrnamentalTitle instance text to "TUTORIAL" |
| `Text("Continue")` on a Button | Override Button instance label to "CONTINUE" |
| `Text("Session Complete")` | Set text to "SESSION COMPLETE" (if uppercase in Swift) |
| `Text("\(character.name)")` | Use realistic placeholder: "DarkKnight42" |
| `Text("\(gold) Gold")` | Use realistic placeholder: "1,250 Gold" |
| `Text("Lv.\(level)")` | Use realistic placeholder: "Lv.38" |

**Default component text is NEVER acceptable.** Every instance must have its text overridden to match the screen context.

### How to override instance text:

```javascript
// Find text nodes inside an instance and override
function overrideInstanceText(instance, overrides) {
  // overrides = { 'TITLE': 'New Title', 'SUBTITLE': 'New Sub' }
  const walk = (node) => {
    if (node.type === 'TEXT') {
      for (const [defaultText, newText] of Object.entries(overrides)) {
        if (node.characters.toUpperCase().includes(defaultText.toUpperCase())) {
          // Must load font before changing characters
          figma.loadFontAsync(node.fontName).then(() => {
            node.characters = newText;
          });
        }
      }
    }
    if ('children' in node) node.children.forEach(walk);
  };
  walk(instance);
}
```

---

## Rule 7: MANDATORY Post-Creation Audit

**After creating ANY screen, run this audit script. If it fails → fix before moving on.**

```javascript
async function auditScreen(screenId) {
  const node = await figma.getNodeByIdAsync(screenId);
  const failures = [];
  let totalText = 0, styledText = 0;
  let totalFills = 0, boundFills = 0;
  let instanceCount = 0, rawFrameCount = 0;

  function walk(n) {
    // Skip inside instances — they inherit from DS
    if (n.type === 'INSTANCE') { instanceCount++; return; }

    if (n.type === 'TEXT') {
      totalText++;
      if (n.textStyleId && n.textStyleId !== '') styledText++;
      else failures.push(`UNSTYLED TEXT: "${n.characters.substring(0,30)}" (${n.id})`);
    }

    if (n.type === 'FRAME') rawFrameCount++;

    if (n.fills && Array.isArray(n.fills) && n.fills.length > 0 && n.fills.some(f => f.visible !== false)) {
      totalFills++;
      const hasBound = n.boundVariables?.fills?.length > 0;
      if (hasBound) boundFills++;
      else {
        const f = n.fills[0];
        const hex = f.color ? `#${Math.round(f.color.r*255).toString(16).padStart(2,'0')}${Math.round(f.color.g*255).toString(16).padStart(2,'0')}${Math.round(f.color.b*255).toString(16).padStart(2,'0')}` : 'gradient';
        failures.push(`HARDCODED FILL: ${n.type}:"${n.name}" → ${hex} (${n.id})`);
      }
    }

    if ('children' in n) n.children.forEach(walk);
  }
  walk(node);

  const textScore = totalText > 0 ? Math.round(styledText/totalText*100) : 100;
  const fillScore = totalFills > 0 ? Math.round(boundFills/totalFills*100) : 100;

  const result = {
    screen: node.name,
    textScore: `${textScore}% (${styledText}/${totalText})`,
    fillScore: `${fillScore}% (${boundFills}/${totalFills})`,
    instances: instanceCount,
    rawFrames: rawFrameCount,
    pass: failures.length === 0,
    failures: failures.slice(0, 10)
  };

  return result;
}

// Usage after screen creation:
const audit = await auditScreen('NEW_SCREEN_ID');
if (!audit.pass) {
  return `AUDIT FAILED:\n${audit.failures.join('\n')}\n\nScores: Text ${audit.textScore}, Fills ${audit.fillScore}`;
}
return `AUDIT PASSED: Text ${audit.textScore}, Fills ${audit.fillScore}, Instances: ${audit.instances}`;
```

### Acceptance Criteria:

| Metric | Required | Acceptable |
|---|---|---|
| Text styled % | 100% | — |
| Fill bound % | 100% | 90% (only screen root frame allowed unbound if needed) |
| Instance count | ≥ 50% of total child nodes | — |
| Default text remaining | 0 | — |

**If audit fails → DO NOT proceed to next screen. Fix first.**

---

## Rule 8: Helper Function Template

Every screen-building script MUST start with these helpers loaded:

```javascript
// === MANDATORY HELPERS ===

// Library references (resolve once, reuse)
const LIB_KEY = 'lk-1e3d5b13e106c557d2ec56c3ac95231374bc21a6136997e732d7a804ec4d86c11297eee6bd376c1bc936574dd6ba4ddea2380be439e8701a5408d7daaff18fb4';

const TEXT_STYLE_KEYS = {
  cinematicTitle: '9c11a0c58dae12b273c8a237e9b0b98450eaebf1',
  title: 'ce245f83ac721aeb90db5258e80bedcfaa4e8cae',
  section: '460e0abe0ddacaefa8b6f698fb61f27a04af7759',
  cardTitle: '24f763b8b7ec47532b5c5f77d77375124f082210',
  buttonLabel: '197938eeaef9704d5ddf2e6efe8c6986d62b6b7f',
  buttonLabelCompact: 'e5461cffd767dc18fc4ea03d3d5fcf7bff1f289c',
  body: 'fef6dd502465059c68ca8041a45afbee2ed690f1',
  uiLabel: 'b147294861bbd172aee02c25d4dd88c13c3a6b80',
  caption: '1d94244a59a22997f3f590d3ad9209b702a7a71d',
  badge: '71f8c0a0806a1197ef63e77a0a591a5bfeac5a95',
};

const EFFECT_STYLE_KEYS = {
  shadowCard: '492a984d82c5f4febf620e4ff807e01a21521209',
  shadowModal: '1452cba48fb12135a3e248ea91e548c38c64133e',
  shadowGoldGlow: '765a5605d7606710559e71a6a24e473e70461c1c',
  shadowDangerGlow: '35769d68a9327b01327c68baca2442868f16b19b',
};

// Cache imported styles
const _styleCache = {};
async function getTextStyle(key) {
  if (!_styleCache[key]) {
    _styleCache[key] = await figma.importStyleByKeyAsync(TEXT_STYLE_KEYS[key]);
  }
  return _styleCache[key];
}

async function getEffectStyle(key) {
  if (!_styleCache['e_' + key]) {
    _styleCache['e_' + key] = await figma.importStyleByKeyAsync(EFFECT_STYLE_KEYS[key]);
  }
  return _styleCache['e_' + key];
}

// Create styled text node
async function makeText(chars, styleKey, colorVarName) {
  const text = figma.createText();
  const style = await getTextStyle(styleKey);

  // Load the font that the style uses
  const fontName = style.fontName || { family: 'Inter', style: 'Regular' };
  await figma.loadFontAsync(fontName);

  text.characters = chars;
  text.textStyleId = style.id;

  // Bind color variable if provided
  if (colorVarName) {
    await bindFill(text, colorVarName);
  }

  return text;
}

// Bind fill to Color variable from published library
const _varCache = {};
async function getColorVar(varName) {
  if (_varCache[varName]) return _varCache[varName];

  // Try to find in library collections
  const collections = await figma.teamLibrary.getAvailableLibraryVariableCollectionsAsync();
  for (const coll of collections) {
    if (coll.name === 'Color' || coll.name === 'Spacing') {
      const vars = await figma.teamLibrary.getVariablesInLibraryCollectionAsync(coll.key);
      const found = vars.find(v => v.name === varName);
      if (found) {
        const imported = await figma.variables.importVariableByKeyAsync(found.key);
        _varCache[varName] = imported;
        return imported;
      }
    }
  }
  throw new Error(`Variable "${varName}" not found in library!`);
}

async function bindFill(node, colorVarName) {
  const variable = await getColorVar(colorVarName);
  node.fills = [figma.variables.setBoundVariableForPaint(
    { type: 'SOLID', color: { r: 0, g: 0, b: 0 } },
    'color',
    variable
  )];
}

async function bindSpacing(node, property, spacingVarName) {
  const variable = await getColorVar(spacingVarName); // same function works for spacing
  node.setBoundVariable(property, variable.id);
}

// Create standard screen frame
async function makeScreenFrame(name) {
  const screen = figma.createFrame();
  screen.name = name;
  screen.resize(390, 844);
  screen.layoutMode = 'VERTICAL';
  screen.primaryAxisAlignItems = 'MIN';
  screen.counterAxisAlignItems = 'CENTER';
  screen.clipsContent = true;
  screen.paddingTop = 60;

  await bindFill(screen, 'color/bg/primary');

  return screen;
}

// Import DS component by key and create instance
async function importComponent(variantKey) {
  const comp = await figma.importComponentByKeyAsync(variantKey);
  return comp.createInstance();
}

// Add instance to parent with FILL width
function addToParent(parent, instance) {
  parent.appendChild(instance);
  instance.layoutSizingHorizontal = 'FILL';
}
```

---

## Workflow Checklist (print and follow)

- [ ] 1. Read Swift source file — extract ALL texts, tokens, components
- [ ] 2. Create truth table: Swift property → Figma binding
- [ ] 3. Search DS for all component keys needed (`search_design_system`)
- [ ] 4. Get variant keys from DS file (query COMPONENT_SET children)
- [ ] 5. Write screen script using MANDATORY HELPERS (Rule 8)
- [ ] 6. Every `createText()` → MUST call `getTextStyle()` + `bindFill()`
- [ ] 7. Every frame fill → MUST call `bindFill()` with variable name
- [ ] 8. Every button/card/badge → MUST use `importComponent()` with variant key
- [ ] 9. Override ALL default instance text to match Swift content
- [ ] 10. Run audit script (Rule 7) — **MUST PASS before proceeding**
- [ ] 11. Take screenshot — visually verify against iOS simulator
