(() => {
  // 바니트 한정 판매 배너 — 2026-05-27 KST 자정 이후 자동 숨김
  const promoBanner = document.getElementById('promo-banner');
  if (promoBanner) {
    // KST 캘린더 날짜 기준으로 일수 계산 (시간대 무관)
    const KST_OFFSET = 9 * 3600000;
    const nowKst = new Date(Date.now() + KST_OFFSET);
    const todayUtc = Date.UTC(nowKst.getUTCFullYear(), nowKst.getUTCMonth(), nowKst.getUTCDate());
    const endUtc = Date.UTC(2026, 4, 27); // 5월 27일
    const daysLeft = (endUtc - todayUtc) / 86400000;
    if (daysLeft >= 0) {
      const ddayEl = document.getElementById('promo-dday');
      if (ddayEl) ddayEl.textContent = `D-${daysLeft}`;
      promoBanner.hidden = false;
    }
  }

  // 공유 버튼 — 모바일은 Web Share API, 데스크탑은 클립보드 복사
  const SHARE_URL = 'https://moongcigongbang.github.io/crochet-basics/';
  const toast = document.getElementById('toast');
  const showToast = (msg, long = false) => {
    if (!toast) return;
    toast.textContent = msg;
    toast.classList.toggle('long', long);
    toast.classList.add('show');
    clearTimeout(showToast._t);
    showToast._t = setTimeout(() => toast.classList.remove('show'), long ? 4500 : 1800);
  };
  // 홈 화면 추가 — Android는 beforeinstallprompt, iOS는 안내 토스트
  const installBtn = document.getElementById('install-btn');
  const isStandalone = window.matchMedia('(display-mode: standalone)').matches
    || window.navigator.standalone === true;
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
  let deferredPrompt = null;

  // 이미 PWA로 설치돼 실행 중인 경우만 버튼 숨김
  if (installBtn && isStandalone) installBtn.hidden = true;

  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
  });
  window.addEventListener('appinstalled', () => {
    if (installBtn) installBtn.hidden = true;
    deferredPrompt = null;
  });

  if (installBtn) {
    installBtn.addEventListener('click', async () => {
      if (deferredPrompt) {
        deferredPrompt.prompt();
        try { await deferredPrompt.userChoice; } catch {}
        deferredPrompt = null;
        installBtn.hidden = true;
      } else if (isIOS) {
        showToast('하단 공유 버튼 → "홈 화면에 추가"', true);
      } else {
        showToast('브라우저 메뉴에서 "앱 설치" 또는 "홈 화면에 추가"를 선택하세요', true);
      }
    });
  }

  const shareBtn = document.getElementById('share-btn');
  if (shareBtn) {
    shareBtn.addEventListener('click', async () => {
      const data = {
        title: '코바늘 기초기법',
        text: '뭉치공방 코바늘 기초기법 영상 모음',
        url: SHARE_URL,
      };
      if (navigator.share) {
        try { await navigator.share(data); } catch {}
        return;
      }
      try {
        await navigator.clipboard.writeText(SHARE_URL);
        showToast('링크가 복사됐어요');
      } catch {
        showToast('복사 실패 — 직접 주소를 복사해주세요');
      }
    });
  }

  const grid = document.getElementById('grid');
  const productsSection = document.getElementById('products-section');
  const productsGrid = document.getElementById('products-grid');
  const search = document.getElementById('search');
  const clearBtn = document.getElementById('clear-btn');
  const emptyEl = document.getElementById('empty');
  const countEl = document.getElementById('result-count');
  const metaEl = document.getElementById('playlist-meta');
  const titleEl = document.getElementById('playlist-title');
  const modal = document.getElementById('modal');
  const player = document.getElementById('player');
  const modalTitle = document.getElementById('modal-title');
  const modalYtLink = document.getElementById('modal-open-yt');

  let videos = [];
  let products = [];
  let query = '';

  const formatDuration = (sec) => {
    if (!sec || isNaN(sec)) return '';
    sec = Math.round(sec);
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    const pad = (n) => String(n).padStart(2, '0');
    return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
  };

  const escapeHtml = (s) =>
    s.replace(/[&<>"']/g, (c) => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[c]));

  const highlight = (title, q) => {
    const safe = escapeHtml(title);
    if (!q) return safe;
    const escaped = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return safe.replace(new RegExp(escaped, 'gi'), (m) => `<mark>${m}</mark>`);
  };

  const matches = (video, q) => {
    if (!q) return true;
    const needle = q.toLowerCase().trim();
    if (video.title.toLowerCase().includes(needle)) return true;
    if (video.keywords) {
      for (const k of video.keywords) {
        if (k.toLowerCase().includes(needle)) return true;
      }
    }
    return false;
  };

  const renderCard = (v, q) => `
    <article class="card" data-id="${v.id}" data-title="${escapeHtml(v.title)}" tabindex="0" role="button" aria-label="${escapeHtml(v.title)}">
      <div class="thumb">
        <img src="${v.thumbnail}" alt="" loading="lazy" />
        ${v.duration ? `<span class="duration">${formatDuration(v.duration)}</span>` : ''}
      </div>
      <div class="card-body">
        <h3 class="card-title">${highlight(v.title, q)}</h3>
      </div>
    </article>
  `;

  const CATEGORY_ORDER = [
    '기초 뜨개법',
    '코 늘리기',
    '코 줄이기',
    '변형 뜨개법',
    '코드 & 매듭',
    '심화·마무리 팁',
  ];

  const render = () => {
    const q = query.trim();
    const filtered = videos.filter((v) => matches(v, q));

    // 카테고리별 그룹핑
    const groups = new Map();
    for (const v of filtered) {
      const cat = v.category || '기타';
      if (!groups.has(cat)) groups.set(cat, []);
      groups.get(cat).push(v);
    }

    // CATEGORY_ORDER 순서로 섹션 렌더
    const knownCats = new Set(CATEGORY_ORDER);
    const extraCats = [...groups.keys()].filter((c) => !knownCats.has(c));
    const orderedCats = [...CATEGORY_ORDER, ...extraCats];

    const sections = [];
    for (const cat of orderedCats) {
      const list = groups.get(cat);
      if (!list || !list.length) continue;
      sections.push(`
        <section class="cat-section">
          <h2 class="cat-header">${escapeHtml(cat)}<span class="cat-count">${list.length}</span></h2>
          <div class="cat-grid">${list.map((v) => renderCard(v, q)).join('')}</div>
        </section>
      `);
    }
    grid.innerHTML = sections.join('');

    emptyEl.hidden = filtered.length !== 0;
    countEl.textContent = q
      ? `${filtered.length}개 결과 (전체 ${videos.length})`
      : `전체 ${videos.length}개 영상`;
    clearBtn.hidden = !q;

    // 상품 코너: 검색 중이 아닐 때만 노출
    if (!q && products.length) {
      productsGrid.innerHTML = products.map((v) => renderCard(v, '')).join('');
      productsSection.hidden = false;
    } else {
      productsSection.hidden = true;
    }
  };

  const openModal = (id, title) => {
    player.src = `https://www.youtube.com/embed/${id}?autoplay=1&rel=0`;
    modalTitle.textContent = title;
    modalYtLink.href = `https://www.youtube.com/watch?v=${id}`;
    modal.hidden = false;
    document.body.style.overflow = 'hidden';
  };

  const closeModal = () => {
    modal.hidden = true;
    player.src = '';
    document.body.style.overflow = '';
  };

  grid.addEventListener('click', (e) => {
    const card = e.target.closest('.card');
    if (!card) return;
    openModal(card.dataset.id, card.dataset.title);
  });

  grid.addEventListener('keydown', (e) => {
    if (e.key !== 'Enter' && e.key !== ' ') return;
    const card = e.target.closest('.card');
    if (!card) return;
    e.preventDefault();
    openModal(card.dataset.id, card.dataset.title);
  });

  modal.addEventListener('click', (e) => {
    if (e.target.dataset.close !== undefined) closeModal();
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !modal.hidden) closeModal();
  });

  search.addEventListener('input', (e) => {
    query = e.target.value;
    render();
  });

  clearBtn.addEventListener('click', () => {
    search.value = '';
    query = '';
    search.focus();
    render();
  });

  fetch('videos.json?v=' + Date.now())
    .then((r) => r.json())
    .then((data) => {
      videos = data.videos || [];
      products = data.products || [];
      titleEl.textContent = data.playlist_title || '코바늘 기초기법';
      metaEl.textContent = `${data.channel || ''} · ${videos.length}개 영상`;
      render();
    })
    .catch((err) => {
      grid.innerHTML = '';
      emptyEl.hidden = false;
      emptyEl.textContent = '영상 목록을 불러오지 못했습니다.';
      console.error(err);
    });
})();
