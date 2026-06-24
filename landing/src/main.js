import QRCode from 'qrcode'

// ── Theme toggle ──────────────────────────────────────────────
const html = document.documentElement
const themeBtn = document.getElementById('themeBtn')

function setTheme(t) {
  html.setAttribute('data-theme', t)
  localStorage.setItem('thebase-theme', t)
}

const saved = localStorage.getItem('thebase-theme')
const sys   = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
setTheme(saved ?? sys)

themeBtn.addEventListener('click', () => {
  setTheme(html.dataset.theme === 'dark' ? 'light' : 'dark')
})

// ── Mobile menu ───────────────────────────────────────────────
const hamburger  = document.getElementById('hamburger')
const mobileMenu = document.getElementById('mobileMenu')

hamburger.addEventListener('click', () => {
  const isOpen = mobileMenu.classList.toggle('open')
  hamburger.classList.toggle('open', isOpen)
  hamburger.setAttribute('aria-expanded', isOpen)
  mobileMenu.setAttribute('aria-hidden', !isOpen)
})

// Close drawer when a link is clicked
mobileMenu.querySelectorAll('a').forEach(a => {
  a.addEventListener('click', () => {
    mobileMenu.classList.remove('open')
    hamburger.classList.remove('open')
    hamburger.setAttribute('aria-expanded', false)
    mobileMenu.setAttribute('aria-hidden', true)
  })
})

// ── Navbar shadow on scroll ───────────────────────────────────
const nav = document.getElementById('nav')
window.addEventListener('scroll', () => {
  nav.style.boxShadow = window.scrollY > 8
    ? '0 2px 16px rgba(0,0,0,.12)'
    : 'none'
}, { passive: true })

// ── Footer year ───────────────────────────────────────────────
document.getElementById('year').textContent = new Date().getFullYear()

// ── QR Code ───────────────────────────────────────────────────
const DOWNLOAD_URL = 'https://github.com/TheWiche/the-base/releases/latest/download/the-base.apk'

const canvas = document.getElementById('qrCanvas')
if (canvas) {
  QRCode.toCanvas(canvas, DOWNLOAD_URL, {
    width: 180,
    margin: 2,
    color: {
      dark: '#000000',
      light: '#ffffff',
    },
  })
}

// ── Scroll reveal ─────────────────────────────────────────────
const observer = new IntersectionObserver(
  entries => entries.forEach(e => {
    if (e.isIntersecting) {
      e.target.classList.add('visible')
      observer.unobserve(e.target)
    }
  }),
  { threshold: 0.12 }
)

document.querySelectorAll('.card, .cta-text, .section-title, .section-desc').forEach(el => {
  el.classList.add('reveal')
  observer.observe(el)
})

// ── Version badge from GitHub ──────────────────────────────────
const GITHUB_REPO = 'TheWiche/the-base'

async function fetchLatestVersion() {
  try {
    const res  = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/releases/latest`)
    if (!res.ok) return
    const data = await res.json()
    const tag  = data.tag_name?.replace(/^v/, '') ?? null
    if (tag) {
      const badge = document.getElementById('versionBadge')
      if (badge) badge.textContent = `v${tag}`
    }
  } catch { /* silently ignore */ }
}

fetchLatestVersion()
