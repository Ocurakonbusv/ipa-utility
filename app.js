/* IPA Utility behavior: local-only input state, explicit confirmation, no credential upload, manifest URL handoff only. */
const $ = (id) => document.getElementById(id);
const files = { ipa: null, cert: null, profile: null };
const inputs = { ipa: $('ipaFile'), cert: $('certFile'), profile: $('profileFile') };
const names = { ipa: $('ipaName'), cert: $('certName'), profile: $('profileName') };
const cards = { ipa: inputs.ipa.closest('.file-card'), cert: inputs.cert.closest('.file-card'), profile: inputs.profile.closest('.file-card') };
const state = $('workflowState');
const prepareButton = $('prepareButton');
const resetButton = $('resetButton');
const dialog = $('confirmDialog');
const dialogFileName = $('dialogFileName');
const progressBar = $('progressBar');
const progressPercent = $('progressPercent');
const progressTitle = $('progressTitle');
const progressDetail = $('progressDetail');
const manifestUrl = $('manifestUrl');
const installButton = $('installButton');
const installHint = $('installHint');
const toast = $('toast');
let toastTimer;

function showToast(message) {
  toast.textContent = message;
  toast.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('show'), 3600);
}

function validExtension(file, allowed) {
  if (!file) return false;
  const name = file.name.toLowerCase();
  return allowed.some((extension) => name.endsWith(extension));
}

function updateState() {
  const hasIpa = Boolean(files.ipa);
  prepareButton.disabled = !hasIpa;
  if (!hasIpa) {
    state.textContent = '待機中';
    progressTitle.textContent = 'ファイルの入力を待っています';
    progressDetail.textContent = 'IPAを選択すると次の操作が有効になります。';
    return;
  }
  state.textContent = 'IPA準備済み';
  progressTitle.textContent = 'IPAを確認しました';
  progressDetail.textContent = '書き込み準備を押すと、次の確認画面へ進みます。';
}

function attachInput(key, allowed) {
  inputs[key].addEventListener('change', () => {
    const file = inputs[key].files?.[0] || null;
    files[key] = file;
    cards[key].classList.remove('is-invalid');
    if (!file) {
      names[key].textContent = '未選択';
      cards[key].classList.remove('is-ready');
      updateState();
      return;
    }
    const valid = validExtension(file, allowed);
    cards[key].classList.toggle('is-ready', valid);
    cards[key].classList.toggle('is-invalid', !valid);
    names[key].textContent = valid ? file.name : '形式を確認してください';
    if (!valid) showToast(`${key === 'ipa' ? 'IPA' : key === 'cert' ? '証明書' : 'プロファイル'}の形式が正しくありません。`);
    updateState();
  });
}

attachInput('ipa', ['.ipa']);
attachInput('cert', ['.p12', '.pfx']);
attachInput('profile', ['.mobileprovision']);

prepareButton.addEventListener('click', () => {
  if (!files.ipa || !validExtension(files.ipa, ['.ipa'])) {
    showToast('先に有効なIPAファイルを選択してください。');
    return;
  }
  dialogFileName.textContent = `${files.ipa.name} を書き込み準備します。公開版では署名処理は実行されません。`;
  dialog.showModal();
});

$('cancelDialog').addEventListener('click', () => dialog.close());
$('confirmDialogButton').addEventListener('click', () => {
  dialog.close();
  runPreparation();
});

function setProgress(value, title, detail) {
  progressBar.style.width = `${value}%`;
  progressPercent.textContent = `${value}%`;
  progressTitle.textContent = title;
  progressDetail.textContent = detail;
}

function runPreparation() {
  state.textContent = '準備中';
  prepareButton.disabled = true;
  setProgress(18, '入力を確認しています', 'IPAの拡張子とファイル名を確認しました。');
  setTimeout(() => setProgress(48, '署名入力を確認しています', files.cert && files.profile ? '証明書とプロファイルを選択済みです。' : '証明書とプロファイルは未選択です。実署名には両方が必要です。'), 420);
  setTimeout(() => {
    setProgress(100, '準備状態を保存しました', '署名サーバー接続後、この位置で再署名ジョブへ接続します。');
    state.textContent = '確認済み';
    prepareButton.disabled = false;
    showToast('書き込み準備が完了しました。');
  }, 980);
}

manifestUrl.addEventListener('input', () => {
  let url;
  try { url = new URL(manifestUrl.value.trim()); } catch { url = null; }
  const valid = Boolean(url && url.protocol === 'https:' && url.pathname.toLowerCase().endsWith('.plist'));
  installButton.disabled = !valid;
  installHint.textContent = valid ? 'HTTPSのmanifestを確認しました。iPhoneから開始できます。' : '現在は署名サーバー未接続です。';
  installHint.style.color = valid ? 'var(--green)' : '';
});

installButton.addEventListener('click', () => {
  const url = encodeURIComponent(manifestUrl.value.trim());
  window.location.href = `itms-services://?action=download-manifest&url=${url}`;
});

resetButton.addEventListener('click', () => {
  Object.keys(inputs).forEach((key) => { inputs[key].value = ''; files[key] = null; names[key].textContent = '未選択'; cards[key].classList.remove('is-ready', 'is-invalid'); });
  manifestUrl.value = '';
  installButton.disabled = true;
  installHint.textContent = '現在は署名サーバー未接続です。';
  installHint.style.color = '';
  setProgress(0, 'ファイルの入力を待っています', 'IPAを選択すると次の操作が有効になります。');
  updateState();
  showToast('入力をリセットしました。');
});

updateState();
