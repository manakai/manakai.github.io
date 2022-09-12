(() => {
  var s = document.createElement ('script');
  s.src = "https://www.googletagmanager.com/gtag/js?id=G-XZKJBG5SSR";
  document.head.appendChild (s);
}) ();

window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', 'G-XZKJBG5SSR');

(() => {
  var ads = document.querySelector ('sw-ads');
  if (!ads) return;

  var c = document.createElement ('aside');
  if (ads.hasAttribute ('normal') &&
      !ads.hasAttribute ('sensitive') &&
      !ads.hasAttribute ('error') &&
      !ads.hasAttribute ('empty') &&
      !ads.hasAttribute ('ugc')) {
    c.innerHTML = `
      <ins class="adsbygoogle" style="display:block" data-ad-client="ca-pub-6943204637055835" data-ad-slot="7192705117" data-ad-format="auto"></ins>
    `;
    var s1 = document.createElement ('script');
    s1.textContent = `
      (adsbygoogle = window.adsbygoogle || []).push({});
    `;
    c.appendChild (s1);
    var s2 = document.createElement ('script');
    s2.src = "https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js";
    c.appendChild (s2);
    ads.appendChild (c);
  } else {
    c.innerHTML = `
      <div class="admax-switch" data-admax-id="219b1f2b7b01e4f815f957e032074f75" style="display:inline-block;"></div>
    `;
    var s1 = document.createElement ('s1');
    s1.textContent = `
      (admaxads = window.admaxads || []).push({admax_id: "219b1f2b7b01e4f815f957e032074f75",type: "switch"});
    `;
    c.appendChild (s1);
    ads.appendChild (c);
  }
}) ();

/* License: Public Domain. */
