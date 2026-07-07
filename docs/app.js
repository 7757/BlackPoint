const supportedLanguages = ["en", "zh"];
const installCommand = "curl -fsSL https://7757.github.io/BlackPoint/install.sh | bash";

function pickInitialLanguage() {
  const stored = localStorage.getItem("blackpoint-language");
  if (supportedLanguages.includes(stored)) return stored;

  const language = navigator.language.toLowerCase();
  if (language.startsWith("zh")) return "zh";
  return "en";
}

function translate(language) {
  const dictionary = window.BLACKPOINT_I18N[language] || window.BLACKPOINT_I18N.en;
  document.documentElement.lang = language === "zh" ? "zh-CN" : language;

  document.querySelectorAll("[data-i18n]").forEach((node) => {
    const value = dictionary[node.dataset.i18n];
    if (value) node.textContent = value;
  });

  document.querySelectorAll("[data-lang]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.lang === language);
  });
}

async function updateStats() {
  try {
    const response = await fetch("https://api.github.com/repos/7757/BlackPoint/releases", {
      headers: { Accept: "application/vnd.github+json" }
    });
    if (response.ok) {
      const releases = await response.json();
      const total = releases.flatMap((release) => release.assets || [])
        .reduce((sum, asset) => sum + (asset.download_count || 0), 0);
      document.querySelector("[data-downloads]").textContent = String(total);
      document.querySelector("[data-downloads-wrap]").hidden = false;
    }
  } catch {
  }

  try {
    const response = await fetch("https://blackpoint.goatcounter.com/counter/TOTAL.json");
    if (response.ok) {
      const result = await response.json();
      const count = result.count || result.count_unique;
      if (count) {
        document.querySelector("[data-visits]").textContent = String(count);
        document.querySelector("[data-visits-wrap]").hidden = false;
      }
    }
  } catch {
  }
}

document.querySelector("[data-install-command]").textContent = installCommand;

document.querySelector("[data-copy-install]").addEventListener("click", async (event) => {
  const language = localStorage.getItem("blackpoint-language") || pickInitialLanguage();
  const dictionary = window.BLACKPOINT_I18N[language] || window.BLACKPOINT_I18N.en;

  await navigator.clipboard.writeText(installCommand);
  event.currentTarget.textContent = dictionary["install.copied"];
  setTimeout(() => {
    event.currentTarget.textContent = dictionary["install.copy"];
  }, 1400);
});

document.querySelectorAll("[data-lang]").forEach((button) => {
  button.addEventListener("click", () => {
    localStorage.setItem("blackpoint-language", button.dataset.lang);
    translate(button.dataset.lang);
  });
});

const header = document.querySelector("[data-header]");
function updateHeader() {
  header.classList.toggle("is-scrolled", window.scrollY > 10);
}

window.addEventListener("scroll", updateHeader, { passive: true });
updateHeader();

const initialLanguage = pickInitialLanguage();
localStorage.setItem("blackpoint-language", initialLanguage);
translate(initialLanguage);
updateStats();
