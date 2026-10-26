const { chromium } = require('C:/Users/HP/.agents/skills/playwright/node_modules/playwright-core');
const results = [];
const check = (name, ok, extra = '') => { results.push([ok ? 'PASS' : 'FAIL', name, extra]); console.log(`${ok ? 'PASS' : 'FAIL'} - ${name}${extra ? ' (' + extra + ')' : ''}`); };

(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 1500, height: 950 } });
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  page.on('dialog', d => d.accept());

  // 1. Login
  await page.goto('http://localhost/SmartTrack/frontend/login.html', { waitUntil: 'load' });
  await page.fill('#email, input[type="email"]', 'jpayla@csucc.edu.ph');
  await page.fill('#password, input[type="password"]', 'FacultyPass123!');
  await page.click('#loginButton, button[type="submit"]');
  await page.waitForURL(/dashboard-faculty/, { timeout: 15000 }).catch(() => {});
  await page.waitForTimeout(2500);
  check('login -> faculty dashboard', page.url().includes('dashboard-faculty'));

  // 2. Travel Records section
  await page.click('.nav-item[data-page="travels"] .nav-link');
  await page.waitForTimeout(1500);
  let rows = await page.$$eval('#travelsTableBody tr', rs => rs.length);
  check('travels section loads rows', rows >= 1, `${rows} rows`);
  const yearOpts = await page.$$eval('#travelYearFilter option', os => os.map(o => o.textContent));
  check('travel year filter populated', yearOpts.length >= 2, yearOpts.join(','));

  // 3. Add travel
  await page.click('#travelsAddBtn');
  await page.waitForTimeout(300);
  await page.fill('#eventTitle', 'E2E Faculty Conference Test');
  await page.selectOption('#activityType', 'International Conference');
  await page.fill('#country', 'Japan');
  await page.fill('#location', 'Tokyo');
  await page.fill('#startDate', '2026-12-01');
  await page.fill('#endDate', '2026-12-05');
  await page.click('#addTravelForm button[type="submit"]');
  await page.waitForTimeout(2000);
  rows = await page.$$eval('#travelsTableBody tr', rs => rs.map(r => r.textContent).join('|'));
  check('add travel -> row appears', rows.includes('E2E Faculty Conference Test'));
  const travelId = await page.evaluate(async () => {
    const t = await api.getTravels();
    const f = t.find(x => x.event_title === 'E2E Faculty Conference Test');
    return f ? f.travel_id : null;
  });
  check('travel created in DB', !!travelId, 'id=' + travelId);

  // 4. Edit travel
  await page.click(`.edit-travel[data-id="${travelId}"]`);
  await page.waitForTimeout(300);
  await page.fill('#eEventTitle', 'E2E Faculty Conference Edited');
  await page.selectOption('#eTimelineStatus', 'Upcoming');
  await page.click('#editTravelForm button[type="submit"]');
  await page.waitForTimeout(1500);
  rows = await page.$$eval('#travelsTableBody tr', rs => rs.map(r => r.textContent).join('|'));
  check('edit travel -> title updated', rows.includes('E2E Faculty Conference Edited'));

  // 5. Documents: upload
  await page.click('.nav-item[data-page="documents"] .nav-link');
  await page.waitForTimeout(1500);
  await page.click('#uploadDocSectionBtn');
  await page.waitForTimeout(800);
  await page.selectOption('#docTravelSelect', String(travelId));
  const docTypeVal = await page.$eval('#docTypeSelect option:nth-child(2)', o => o.value).catch(() => null);
  check('doc types loaded in select', !!docTypeVal, docTypeVal);
  if (docTypeVal) await page.selectOption('#docTypeSelect', docTypeVal);
  await page.setInputFiles('#docFileInput', { name: 'e2e-test-doc.txt', mimeType: 'text/plain', buffer: Buffer.from('E2E SmartTrack test document') });
  await page.click('#uploadDocSubmitBtn');
  await page.waitForTimeout(2500);
  let docRows = await page.$$eval('#documentsTableBody tr', rs => rs.map(r => r.textContent).join('|'));
  check('document uploaded -> row appears', docRows.includes('e2e-test-doc.txt'));
  const docId = await page.evaluate(async () => {
    const d = await api.getMyDocuments();
    const f = d.find(x => (x.file_name || '').includes('e2e-test-doc'));
    return f ? f.document_id : null;
  });
  check('document in DB', !!docId, 'id=' + docId);

  // 6. Download document (real file endpoint)
  const dlRes = await page.evaluate(async (id) => {
    const token = localStorage.getItem('accessToken');
    const r = await fetch(`http://localhost:5000/api/documents/${id}/file`, { headers: { 'Authorization': 'Bearer ' + token } });
    return { status: r.status, text: r.ok ? await r.text() : '' };
  }, docId);
  check('download file endpoint works', dlRes.status === 200 && dlRes.text.includes('E2E SmartTrack'), 'status ' + dlRes.status);

  // 7. Delete document
  await page.click(`.del-doc[data-id="${docId}"]`);
  await page.waitForTimeout(1500);
  docRows = await page.$$eval('#documentsTableBody tr', rs => rs.map(r => r.textContent).join('|'));
  check('delete document -> row gone', !docRows.includes('e2e-test-doc.txt'));

  // 8. Announcements
  await page.click('.nav-item[data-page="announcements"] .nav-link');
  await page.waitForTimeout(1200);
  const annVisible = await page.isVisible('#announcementsFullList');
  check('announcements section renders', annVisible);

  // 9. Reports
  await page.click('.nav-item[data-page="reports"] .nav-link');
  await page.waitForTimeout(1500);
  const repTotal = await page.textContent('#repTotal');
  check('reports section shows totals', repTotal && repTotal.trim() !== '—', 'total=' + repTotal);
  const repRows = await page.$$eval('#reportTypeBody tr', rs => rs.length);
  check('reports group tables populated', repRows >= 1, repRows + ' type rows');

  // 10. College Records
  await page.click('.nav-item[data-page="college-records"] .nav-link');
  await page.waitForTimeout(2000);
  const cards = await page.$$eval('#collegesGrid .panel-card', cs => cs.length);
  check('college records cards', cards >= 5, cards + ' cards');

  // 11. Analytics
  await page.click('.nav-item[data-page="analytics"] .nav-link');
  await page.waitForTimeout(2000);
  const anTotal = await page.textContent('#anTotal');
  check('analytics stat cards', anTotal && anTotal.trim() !== '—', 'total=' + anTotal);
  const chartOk = await page.evaluate(() => {
    const ids = ['analyticsYearChart', 'analyticsTypeChart', 'analyticsCountryChart'];
    return ids.every(id => { const c = document.getElementById(id); return c && c.width > 0; });
  });
  check('analytics charts rendered', chartOk);

  // 12. Profile
  await page.click('.nav-item[data-page="profile"] .nav-link');
  await page.waitForTimeout(1500);
  const profName = await page.inputValue('#fpName');
  check('profile prefilled', profName && profName.length > 3, profName);
  await page.click('#facultyProfileForm button[type="submit"]');
  await page.waitForTimeout(1200);
  check('profile save toast', await page.isVisible('.toast'));

  // 13. Change password roundtrip (same password) — now in Settings section
  await page.click('.nav-item[data-page="settings"] .nav-link');
  await page.waitForTimeout(1200);
  await page.fill('#fpCurPassword', 'FacultyPass123!');
  await page.fill('#fpNewPassword', 'FacultyPass123!');
  await page.fill('#fpConfirmPassword', 'FacultyPass123!');
  await page.click('#facultyPasswordForm button[type="submit"]');
  await page.waitForTimeout(1500);
  const pwToast = await page.$$eval('.toast', ts => ts.length ? ts[ts.length - 1].textContent : '');
  check('password change works', (pwToast || '').toLowerCase().includes('password changed'), pwToast);

  // 14. Notifications dropdown
  await page.click('#notificationBtn');
  await page.waitForTimeout(500);
  const notifHtml = await page.textContent('#notificationList');
  check('notification dropdown renders', !!notifHtml && !notifHtml.includes('New travel guidelines for SY'), (notifHtml || '').slice(0, 40));
  await page.click('#notificationBtn').catch(() => {});

  // 15. Mobility Plan page
  await page.click('.nav-item[data-page="mobility-plan"] .nav-link');
  await page.waitForURL(/mobility-plan/, { timeout: 8000 }).catch(() => {});
  await page.waitForTimeout(1500);
  check('mobility plan page loads', page.url().includes('mobility-plan'));
  const mpForm = await page.isVisible('#mobilityPlanForm');
  check('mobility plan form present', mpForm);
  // save a plan
  await page.selectOption('#mpReadiness', 'Preparing').catch(() => {});
  await page.fill('#mpCountry', 'Thailand').catch(() => {});
  await page.click('#mobilityPlanForm button[type="submit"], #mpSaveBtn').catch(() => {});
  await page.waitForTimeout(1500);

  // back to dashboard, cleanup: delete E2E travel
  await page.goto('http://localhost/SmartTrack/frontend/dashboard-faculty.html', { waitUntil: 'load' });
  await page.waitForTimeout(2000);
  await page.click('.nav-item[data-page="travels"] .nav-link');
  await page.waitForTimeout(1200);
  await page.click(`.delete-travel[data-id="${travelId}"]`);
  await page.waitForTimeout(1500);
  rows = await page.$$eval('#travelsTableBody tr', rs => rs.map(r => r.textContent).join('|'));
  check('cleanup: test travel deleted', !rows.includes('E2E Faculty Conference'));

  await page.screenshot({ path: 'C:/Users/HP/AppData/Local/Temp/opencode/fac_features_final.png', fullPage: true });

  const fails = results.filter(r => r[0] === 'FAIL');
  console.log(`\nRESULT: ${results.length - fails.length} passed, ${fails.length} failed`);
  console.log('PAGE ERRORS:', errs.length ? errs.join(' | ') : 'none');
  await browser.close();
  process.exit(fails.length ? 1 : 0);
})().catch(e => { console.error('FATAL', e); process.exit(1); });
