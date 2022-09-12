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
  var notes = [];
  
  var ads = document.querySelector ('sw-ads');
  if (ads) {
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

      notes.push ('Google Analytics and Google AdSense are used in this page; <a href=https://www.google.com/policies/privacy/partners/>Cookies are used</a>.');
    } else {
      c.innerHTML = `
        <div class="admax-switch" data-admax-id="219b1f2b7b01e4f815f957e032074f75" style="display:inline-block;"></div>
      `;
      var s1 = document.createElement ('script');
      s1.textContent = `
        (admaxads = window.admaxads || []).push({admax_id: "219b1f2b7b01e4f815f957e032074f75",type: "switch"});
      `;
      c.appendChild (s1);
      var s2 = document.createElement ('script');
      s2.src = "https://adm.shinobi.jp/st/t.js";
      c.appendChild (s2);
      ads.appendChild (c);
      notes.push ('Google Analytics is used in this page; <a href=https://www.google.com/policies/privacy/partners/>Cookies are used</a>.');
      notes.push ('<span lang=ja>\u5FCD\u8005AdMax</span> is used in this page; <a href=https://corp.ninja.co.jp/isplaw/privacy/cookie/>Cookies are used</a>.');
    }
  } else { // no ads
    notes.push ('Google Analytics is used in this page; <a href=https://www.google.com/policies/privacy/partners/>Cookies are used</a>.');
  }

  if (notes.length) {
    var d = document.querySelector ('sw-ads-notes');
    if (!d) {
      d = document.createElement ('sw-ads-notes');
      document.body.appendChild (d);
    }
    d.lang = 'en';
    notes.forEach (n => {
      var t = document.createElement ('span');
      t.innerHTML = n + ' ';
      d.appendChild (t);
    });
  } // notes
}) ();

/* License: Public Domain. */
