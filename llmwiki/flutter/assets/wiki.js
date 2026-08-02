/* LLM Wiki — Flutter. Navigation injector.
 *
 * DESIGN NOTE (deliberate, not an oversight): the sidebar is injected at
 * runtime instead of being duplicated into all 22 pages. Two reasons —
 *  1. A machine reader that extracts text from the static HTML gets the
 *     page's CONTENT, not 22 copies of a navigation list. Repeated
 *     boilerplate is the single biggest source of noise when documentation
 *     is chunked for retrieval.
 *  2. One source of truth for the page order; the same array drives
 *     prev/next and is mirrored by /llms.txt.
 *
 * The machine-readable index is llms.txt. The human index is index.html.
 * Neither depends on this file.
 */

const WIKI_PAGES = [
  { g: 'Start here', n: '00', f: '00-how-to-use-this-wiki.html', t: 'How to use this wiki' },
  { g: 'Start here', n: '01', f: '01-foundations-architecture.html', t: 'Foundations & architecture' },
  { g: 'Method', n: '02', f: '02-specification-driven-development.html', t: 'Specification-driven development' },
  { g: 'Method', n: '03', f: '03-tdd-and-testing.html', t: 'TDD & the test pyramid' },
  { g: 'Method', n: '04', f: '04-robustness.html', t: 'Robustness & error handling' },
  { g: 'Method', n: '05', f: '05-traceability.html', t: 'Traceability & observability' },
  { g: 'Method', n: '27', f: '27-recurring-bugs.html', t: 'Recurring bugs & regressions' },
  { g: 'Data', n: '06', f: '06-caching.html', t: 'Caching' },
  { g: 'Data', n: '07', f: '07-supabase.html', t: 'Supabase backend' },
  { g: 'Data', n: '08', f: '08-authentication.html', t: 'Authentication & Google sign-in' },
  { g: 'Data', n: '09', f: '09-confidentiality.html', t: 'Confidentiality & security' },
  { g: 'Device', n: '10', f: '10-bluetooth.html', t: 'Bluetooth & BLE' },
  { g: 'Device', n: '11', f: '11-barcode-qr.html', t: 'Barcode & QR' },
  { g: 'Device', n: '12', f: '12-nfc-rfid.html', t: 'NFC & RFID' },
  { g: 'Platforms', n: '13', f: '13-android.html', t: 'Android' },
  { g: 'Platforms', n: '14', f: '14-ios.html', t: 'iOS / iPhone' },
  { g: 'Platforms', n: '15', f: '15-macos.html', t: 'macOS' },
  { g: 'Platforms', n: '16', f: '16-windows.html', t: 'Windows' },
  { g: 'Platforms', n: '17', f: '17-fdroid.html', t: 'F-Droid' },
  { g: 'Ship', n: '18', f: '18-github.html', t: 'GitHub: repo, CI & traceable process' },
  { g: 'Ship', n: '19', f: '19-go-live.html', t: 'Go-live runbook' },
  { g: 'Ship', n: '20', f: '20-testers-google-groups.html', t: 'Testers & Google Groups' },
  { g: 'Runtime', n: '21', f: '21-background-and-pinning.html', t: 'Background & always-visible UI' },
  { g: 'Runtime', n: '22', f: '22-maps-openstreetmap.html', t: 'Maps with OpenStreetMap' },
  { g: 'Quality', n: '25', f: '25-performance.html', t: 'Performance' },
  { g: 'Quality', n: '26', f: '26-l10n-time-a11y.html', t: 'Localisation, time & accessibility' },
  { g: 'Collaboration', n: '23', f: '23-github-craft.html', t: 'GitHub craft' },
  { g: 'Collaboration', n: '28', f: '28-ai-agents.html', t: 'Working with AI agents' },
  { g: 'Appendix', n: '24', f: '24-two-projects-compared.html', t: 'Two projects compared' },
];

(function () {
  const here = location.pathname.split('/').pop() || 'index.html';

  // ---- sidebar -------------------------------------------------------
  const side = document.querySelector('.sidebar');
  if (side) {
    let html =
      '<a class="brand" href="index.html"><b>LLM Wiki · Flutter</b>' +
      '<span>field-proven app engineering</span></a>';
    let group = null;
    let open = false;
    for (const p of WIKI_PAGES) {
      if (p.g !== group) {
        if (open) html += '</ol>';
        html += `<div class="nav-group">${p.g}</div><ol>`;
        group = p.g;
        open = true;
      }
      const cur = p.f === here ? ' aria-current="page"' : '';
      html += `<li><a href="${p.f}"${cur}><span class="num">${p.n}</span>${p.t}</a></li>`;
    }
    if (open) html += '</ol>';
    html +=
      '<div class="nav-group">Machine index</div><ol>' +
      '<li><a href="llms.txt"><span class="num">··</span>llms.txt</a></li>' +
      '</ol>';
    side.innerHTML = html;
  }

  // ---- prev / next ---------------------------------------------------
  const foot = document.querySelector('.footnav');
  if (foot) {
    const i = WIKI_PAGES.findIndex((p) => p.f === here);
    const prev = i > 0 ? WIKI_PAGES[i - 1] : null;
    const next = i >= 0 && i < WIKI_PAGES.length - 1 ? WIKI_PAGES[i + 1] : null;
    foot.innerHTML =
      (prev ? `<a href="${prev.f}">← ${prev.n} ${prev.t}</a>` : '<span></span>') +
      (next ? `<a href="${next.f}">${next.n} ${next.t} →</a>` : '<span></span>');
  }

  // ---- anchor links on every chunked section -------------------------
  document.querySelectorAll('section[data-chunk-id] > h2').forEach((h) => {
    const sec = h.parentElement;
    if (!sec.id) return;
    const a = document.createElement('a');
    a.href = '#' + sec.id;
    a.textContent = '#';
    a.setAttribute('aria-label', 'Link to this section');
    a.style.cssText =
      'float:right;text-decoration:none;opacity:.25;font-weight:400;font-size:.8em';
    h.appendChild(a);
  });
})();
