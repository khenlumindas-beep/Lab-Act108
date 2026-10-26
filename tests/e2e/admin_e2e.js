const { chromium } = require('C:/Users/HP/.agents/skills/playwright/node_modules/playwright-core');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let pass = 0, fail = 0;
const check = (name, ok, extra = '') => { ok ? pass++ : fail++; console.log(`${ok ? 'PASS' : 'FAIL'} - ${name}${extra ? ' (' + extra + ')' : ''}`); };
const toastHas = async (page, text) => page.waitForFunction(t => [...document.querySelectorAll('.toast')].some(e => e.textContent.includes(t)), text, { timeout: 6000 }).then(() => true).catch(() => false);

(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 1400, height: 950 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message.slice(0, 200)));
  page.on('dialog', d => d.accept());

  // ===== LOGIN =====
  await page.goto('http://localhost/SmartTrack/frontend/login.html', { waitUntil: 'load' });
  await sleep(1200);
  await page.fill('#email, input[type="email"]', 'oige@csucc.edu.ph');
  await page.fill('#password, input[type="password"]', 'AdminPass123!');
  await page.click('#loginBtn, button[type="submit"]').catch(() => page.keyboard.press('Enter'));
  await page.waitForURL(/dashboard-admin/, { timeout: 15000 });
  await sleep(3500);

  // ===== 1. DASHBOARD REAL DATA =====
  const dash = await page.evaluate(() => ({
    totalTravels: document.getElementById('totalTravels')?.textContent,
    totalUsers: document.getElementById('totalUsers')?.textContent,
    compliance: document.getElementById('complianceStatus')?.textContent,
    colleges: document.getElementById('totalColleges')?.textContent,
    travelTrend: document.getElementById('travelTrend')?.textContent,
    legendRows: document.querySelectorAll('#docLegendList .legend-row').length,
    legendText: document.getElementById('docLegendList')?.textContent.replace(/\s+/g, ' ').slice(0, 120),
    activities: document.querySelectorAll('#recentActivitiesList .activity-item').length,
    currentDate: document.getElementById('currentDate')?.textContent,
    profileName: document.getElementById('profileDisplayName')?.textContent,
    userEmail: document.getElementById('userEmail')?.textContent,
    sysUpcoming: document.getElementById('sysUpcoming')?.textContent,
    sysActiveFaculty: document.getElementById('sysActiveFaculty')?.textContent,
    pendingDocs: document.getElementById('sysPendingDocs')?.textContent
  }));
  check('stat cards loaded (not —)', !['—'].includes(dash.totalTravels) && !['—'].includes(dash.totalUsers) && !['—'].includes(dash.compliance), JSON.stringify({ t: dash.totalTravels, u: dash.totalUsers, c: dash.compliance, col: dash.colleges }));
  check('donut legend real rows >= 3', dash.legendRows >= 3, dash.legendText);
  check('recent activities loaded', dash.activities > 0, `${dash.activities} items`);
  check('current date is real', dash.currentDate !== 'September 22, 2026' && dash.currentDate?.length > 8, dash.currentDate);
  check('profile header real (name+email)', dash.profileName === 'OIGE Admin One' && dash.userEmail === 'oige@csucc.edu.ph', `${dash.profileName} / ${dash.userEmail}`);
  check('system summary real', dash.sysUpcoming !== '—' && dash.sysActiveFaculty !== '—', JSON.stringify({ up: dash.sysUpcoming, fac: dash.sysActiveFaculty, docs: dash.pendingDocs }));
  check('travel trend computed', !!dash.travelTrend && !dash.travelTrend.includes('Loading'), dash.travelTrend);
  await page.screenshot({ path: process.env.TEMP + '/opencode/e2e_1_dashboard.png' });

  // ===== 2. NOTIFICATIONS BELL =====
  await page.click('#notificationBtn');
  await sleep(600);
  const notifEmpty = await page.textContent('#notificationList');
  check('notification dropdown renders', (notifEmpty || '').length > 5, notifEmpty.trim().slice(0, 50));
  await page.click('#notificationBtn'); // close

  // create announcement -> all users notified (incl. admin)
  await page.click('.nav-item[data-page="announcements"] .nav-link');
  await sleep(1500);

  // ===== 3. ANNOUNCEMENTS CRUD =====
  await page.click('#addAnnouncementBtn');
  await sleep(400);
  await page.fill('#annTitle', 'E2E Test Announcement');
  await page.fill('#annContent', 'This is an automated test announcement for the admin functions.');
  await page.click('#annSubmitBtn');
  check('announcement published toast', await toastHas(page, 'published'));
  await sleep(1200);
  let annText = await page.textContent('#announcementsList');
  check('announcement appears in list', (annText || '').includes('E2E Test Announcement'));

  // edit it
  await page.click('#announcementsList .ann-edit');
  await sleep(400);
  const annTitleVal = await page.inputValue('#annTitle');
  check('edit prefills form', annTitleVal === 'E2E Test Announcement', annTitleVal);
  await page.fill('#annTitle', 'E2E Test Announcement EDITED');
  await page.click('#annSubmitBtn');
  check('announcement update toast', await toastHas(page, 'updated'));
  await sleep(1200);
  annText = await page.textContent('#announcementsList');
  check('edited title visible', (annText || '').includes('E2E Test Announcement EDITED'));

  // notifications badge should now be > 0 (announcement notifies all users incl. admin)
  const badge = await page.evaluate(() => {
    const b = document.getElementById('notificationBadge');
    return { text: b?.textContent, display: b?.style.display };
  });
  check('notification badge active after announcement', badge.text !== '0' && badge.display !== 'none', JSON.stringify(badge));

  // deactivate it (cleanup)
  await page.click('#announcementsList .ann-deact');
  await sleep(1200);
  check('announcement deactivated toast', await toastHas(page, 'deactivated'));
  annText = await page.textContent('#announcementsList');
  check('announcement removed from list', !(annText || '').includes('E2E Test Announcement'));

  // mark all read -> badge hides
  await page.click('#notificationBtn');
  await sleep(500);
  await page.click('#markAllReadBtn');
  await sleep(1000);
  const badgeAfter = await page.evaluate(() => document.getElementById('notificationBadge')?.style.display);
  check('mark-all-read hides badge', badgeAfter === 'none', `display=${badgeAfter}`);
  await page.click('#notificationBtn');
  await page.screenshot({ path: process.env.TEMP + '/opencode/e2e_2_announcements.png' });

  // ===== 4. USERS: edit + deactivate/reactivate =====
  await page.click('.nav-item[data-page="users"] .nav-link');
  await sleep(1800);
  // Edit user 7 (Dr. Bocarie T. Sultan)
  await page.click('#usersTableBody .edit-user[data-id="7"]');
  await sleep(800);
  const formState = await page.evaluate(() => ({
    title: document.getElementById('addUserPanelTitle')?.textContent,
    name: document.getElementById('nuName')?.value,
    email: document.getElementById('nuEmail')?.value,
    saveBtn: document.getElementById('saveUserBtn')?.textContent
  }));
  check('user edit form opens prefilled', formState.title === 'Edit User' && formState.name?.length > 3 && formState.email?.includes('@'), JSON.stringify(formState));
  const origDesignation = await page.inputValue('#nuDesignation');
  await page.fill('#nuDesignation', origDesignation ? origDesignation + ' (E2E)' : 'E2E Tester');
  await page.click('#saveUserBtn');
  check('user update toast', await toastHas(page, 'updated'));
  await sleep(1500);
  let usersText = await page.textContent('#usersTableBody');
  check('updated designation in table', (usersText || '').includes('(E2E)'));
  // restore
  await page.click('#usersTableBody .edit-user[data-id="7"]');
  await sleep(700);
  await page.fill('#nuDesignation', origDesignation);
  await page.click('#saveUserBtn');
  await sleep(1500);
  usersText = await page.textContent('#usersTableBody');
  check('designation restored', origDesignation ? !(usersText || '').includes('(E2E)') : true);

  // deactivate + reactivate user 7 (dialog auto-accepted)
  await page.click('#usersTableBody .deactivate-user[data-id="7"]');
  check('deactivate toast', await toastHas(page, 'deactivated'));
  await sleep(1500);
  const hasReactivate = await page.$('#usersTableBody .reactivate-user[data-id="7"]');
  check('reactivate button appears', !!hasReactivate);
  await page.click('#usersTableBody .reactivate-user[data-id="7"]');
  check('reactivate toast', await toastHas(page, 'reactivated'));
  await sleep(1500);
  const hasDeactivate = await page.$('#usersTableBody .deactivate-user[data-id="7"]');
  check('deactivate button back (active)', !!hasDeactivate);
  await page.screenshot({ path: process.env.TEMP + '/opencode/e2e_3_users.png' });

  // ===== 5. DOCUMENT TYPES CRUD =====
  await page.click('.nav-item[data-page="document-types"] .nav-link');
  await sleep(1500);
  let dtRows = await page.$$('#docTypesTableBody tr');
  check('doc types seeded rows >= 8', dtRows.length >= 8, `${dtRows.length} rows`);
  await page.click('#addDocTypeBtn');
  await sleep(400);
  await page.fill('#dtName', 'E2E Compliance Doc');
  await page.selectOption('#dtCategory', 'Post-Travel');
  await page.fill('#dtSort', '50');
  await page.click('#dtSaveBtn');
  check('doc type add toast', await toastHas(page, 'added'));
  await sleep(1200);
  let dtText = await page.textContent('#docTypesTableBody');
  check('new doc type in table', (dtText || '').includes('E2E Compliance Doc'));

  // edit it
  await page.evaluate(() => {
    const btns = [...document.querySelectorAll('#docTypesTableBody .dt-edit')];
    btns.find(b => b.closest('tr').textContent.includes('E2E Compliance Doc'))?.click();
  });
  await sleep(500);
  const dtNameVal = await page.inputValue('#dtName');
  check('doc type edit prefills', dtNameVal === 'E2E Compliance Doc', dtNameVal);
  await page.fill('#dtName', 'E2E Compliance Doc RENAMED');
  await page.click('#dtSaveBtn');
  check('doc type update toast', await toastHas(page, 'updated'));
  await sleep(1200);
  dtText = await page.textContent('#docTypesTableBody');
  check('renamed doc type visible', (dtText || '').includes('E2E Compliance Doc RENAMED'));

  // delete it (cleanup)
  await page.evaluate(() => {
    const btns = [...document.querySelectorAll('#docTypesTableBody .dt-delete')];
    btns.find(b => b.closest('tr').textContent.includes('E2E Compliance Doc RENAMED'))?.click();
  });
  check('doc type delete toast', await toastHas(page, 'deleted'));
  await sleep(1200);
  dtText = await page.textContent('#docTypesTableBody');
  check('doc type removed', !(dtText || '').includes('E2E Compliance Doc RENAMED'));

  // category filter
  await page.selectOption('#dtCategoryFilter', 'Pre-Travel');
  await sleep(900);
  dtText = await page.textContent('#docTypesTableBody');
  const preOk = (dtText || '').includes('Passport') && !(dtText || '').includes('Travel Report');
  check('category filter works', preOk);
  await page.selectOption('#dtCategoryFilter', '');
  await sleep(900);
  await page.screenshot({ path: process.env.TEMP + '/opencode/e2e_4_doctypes.png' });

  // ===== 6. SETTINGS: profile + password =====
  await page.click('.nav-item[data-page="settings"] .nav-link');
  await sleep(1500);
  const prof = await page.evaluate(() => ({
    name: document.getElementById('setName')?.value,
    email: document.getElementById('setEmail')?.value
  }));
  check('settings profile prefilled', prof.name === 'OIGE Admin One' && prof.email === 'oige@csucc.edu.ph', JSON.stringify(prof));

  // save profile (designation roundtrip)
  const origSetDesig = await page.inputValue('#setDesignation');
  await page.fill('#setDesignation', origSetDesig ? origSetDesig + ' (E2E)' : 'E2E Profile');
  await page.click('#profileSettingsForm button[type="submit"]');
  check('profile save toast', await toastHas(page, 'Profile updated'));
  await sleep(1000);
  const headerName = await page.textContent('#profileDisplayName');
  check('header name updated after save', headerName === 'OIGE Admin One', headerName);
  // restore
  await page.fill('#setDesignation', origSetDesig);
  await page.click('#profileSettingsForm button[type="submit"]');
  await sleep(1000);

  // password change: mismatch validation
  await page.fill('#curPassword', 'AdminPass123!');
  await page.fill('#newPassword', 'E2Etestpass1');
  await page.fill('#confirmPassword', 'E2Etestpass2');
  await page.click('#changePasswordForm button[type="submit"]');
  check('mismatch validation toast', await toastHas(page, 'do not match'));

  // wrong current password
  await page.fill('#curPassword', 'TotallyWrong1');
  await page.fill('#newPassword', 'E2Etestpass1');
  await page.fill('#confirmPassword', 'E2Etestpass1');
  await page.click('#changePasswordForm button[type="submit"]');
  check('wrong current password rejected', await toastHas(page, 'incorrect'));

  // real change + change back
  await page.fill('#curPassword', 'AdminPass123!');
  await page.fill('#newPassword', 'E2Etestpass1');
  await page.fill('#confirmPassword', 'E2Etestpass1');
  await page.click('#changePasswordForm button[type="submit"]');
  check('password change success', await toastHas(page, 'changed'));
  await sleep(800);
  await page.fill('#curPassword', 'E2Etestpass1');
  await page.fill('#newPassword', 'AdminPass123!');
  await page.fill('#confirmPassword', 'AdminPass123!');
  await page.click('#changePasswordForm button[type="submit"]');
  check('password restored', await toastHas(page, 'changed'));
  await sleep(800);
  await page.screenshot({ path: process.env.TEMP + '/opencode/e2e_5_settings.png' });

  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  console.log('PAGE ERRORS:', errors.length ? errors : 'none');
  await browser.close();
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error('SCRIPT FAILED:', e.message); process.exit(1); });
