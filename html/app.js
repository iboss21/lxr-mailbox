/**
 * LXR Mailbox - NUI client
 */
(function () {
  const shell = document.getElementById('mailbox-shell');
  const bodyEl = document.getElementById('panel-body');
  const footerEl = document.getElementById('panel-footer');
  const hdrTitle = document.getElementById('hdr-title');
  const hdrSub = document.getElementById('hdr-sub');
  const toastStack = document.getElementById('toast-stack');

  let L = {};
  let state = {
    view: 'main',
    hasMailbox: false,
    nearMailbox: false,
    postalCode: '',
    mailboxId: null,
    mails: [],
    contacts: [],
    selectedMail: null,
    compose: { postal: '', subject: '', message: '', contactName: '' },
    localeStrings: {},
  };

  function esc(s) {
    if (s == null) return '';
    const d = document.createElement('div');
    d.textContent = String(s);
    return d.innerHTML;
  }

  function t(key, fallback) {
    return state.localeStrings[key] || L[key] || fallback || key;
  }

  function resName() {
    return typeof GetParentResourceName === 'function'
      ? GetParentResourceName()
      : 'lxr-mailbox';
  }

  function api(action, payload) {
    return fetch('https://' + resName() + '/mailboxApi', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ action: action, payload: payload || {} }),
    }).then(function (r) {
      return r.json();
    });
  }

  function closeUi() {
    fetch('https://' + resName() + '/closeUi', { method: 'POST', body: '{}' });
  }

  function toast(msg, type) {
    const el = document.createElement('div');
    el.className = 'toast ' + (type || 'info');
    el.textContent = msg;
    toastStack.appendChild(el);
    setTimeout(function () {
      el.remove();
    }, 4200);
  }

  function clearPanels() {
    bodyEl.innerHTML = '';
    footerEl.innerHTML = '';
  }

  function footerButtons(rows) {
    rows.forEach(function (row) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className =
        'btn' +
        (row.primary ? ' primary' : '') +
        (row.danger ? ' danger' : '') +
        (row.ghost ? ' ghost' : '');
      b.textContent = row.label;
      b.onclick = row.onClick;
      footerEl.appendChild(b);
    });
  }

  function renderRegister() {
    hdrTitle.textContent = t('RegisterPageHeader');
    hdrSub.textContent = '';
    bodyEl.innerHTML =
      '<p class="empty-hint">' + esc(t('MailNotRegistered')) + '</p>';
    const ft = [];
    ft.push({
      label: t('MailboxRegistrationButton'),
      primary: true,
      onClick: function () {
        api('RegisterMailbox', {}).then(function (r) {
          if (r && r.ok !== false && r.mailboxId) {
            state.hasMailbox = true;
            state.mailboxId = r.mailboxId;
            state.postalCode = r.postalCode || '';
            state.view = 'main';
            render();
          }
        });
      },
    });
    if (state.nearMailbox) {
      ft.push({
        label: t('PurchaseLetterButton'),
        onClick: function () {
          api('PurchaseLetter', {});
        },
      });
    }
    ft.push({ label: t('BackButtonLabel'), ghost: true, onClick: closeUi });
    footerButtons(ft);
  }

  function renderMain() {
    hdrTitle.textContent = t('MailActionPageHeader');
    hdrSub.textContent =
      t('PostalCodeLabel') + ' ' + esc(state.postalCode || t('MailNotRegistered'));
    bodyEl.innerHTML =
      '<p style="font-size:0.92rem;line-height:1.5;color:var(--muted)">' +
      esc(t('MailboxOptions') || '') +
      '</p>';
    const btns = [
      {
        label: t('SendMailButton'),
        primary: true,
        onClick: function () {
          state.compose = { postal: '', subject: '', message: '', contactName: '' };
          state.view = 'compose';
          render();
        },
      },
      {
        label: t('CheckMailButton'),
        onClick: function () {
          bodyEl.innerHTML =
            '<div class="loading-overlay">' + esc(t('ReceivedMessages')) + '…</div>';
          api('FetchMail', {}).then(function (r) {
            state.mails = (r && r.mails) || [];
            state.view = 'inbox';
            render();
          });
        },
      },
      {
        label: t('ManageContactsButton'),
        onClick: function () {
          api('GetContacts', {}).then(function (r) {
            state.contacts = (r && r.contacts) || [];
            state.view = 'contacts';
            render();
          });
        },
      },
    ];
    if (state.nearMailbox) {
      btns.push({
        label: t('PurchaseLetterButton'),
        onClick: function () {
          api('PurchaseLetter', {});
        },
      });
    }
    footerButtons(btns);
    footerButtons([{ label: t('BackButtonLabel'), ghost: true, onClick: closeUi }]);
  }

  function renderInbox() {
    hdrTitle.textContent = t('ReceivedMessagesHeader');
    hdrSub.textContent = '';
    if (!state.mails.length) {
      bodyEl.innerHTML =
        '<div class="empty-hint">' + esc(t('NoMailsFound')) + '</div>';
    } else {
      const wrap = document.createElement('div');
      wrap.className = 'mail-list';
      state.mails.forEach(function (mail, idx) {
        const row = document.createElement('button');
        row.type = 'button';
        row.className =
          'mail-row' + (Number(mail.is_read) !== 1 ? ' unread' : '');
        const subj = mail.subject || '—';
        const from = mail.from_name || '—';
        const code = mail.from_char || '';
        row.innerHTML =
          '<div><strong>' +
          esc(subj) +
          '</strong></div><div class="mail-meta">' +
          esc(
            idx +
              1 +
              '. ' +
              t('mailFrom') +
              ' ' +
              from +
              ' (' +
              code +
              ')'
          ) +
          '</div>';
        row.onclick = function () {
          state.selectedMail = mail;
          state.view = 'read';
          render();
        };
        wrap.appendChild(row);
      });
      bodyEl.appendChild(wrap);
    }
    footerButtons([
      {
        label: t('BackButtonLabel'),
        onClick: function () {
          state.view = 'main';
          render();
        },
      },
    ]);
  }

  function renderRead() {
    const mail = state.selectedMail;
    if (!mail) {
      state.view = 'main';
      render();
      return;
    }
    hdrTitle.textContent = t('MessageContentHeader');
    hdrSub.textContent =
      t('mailFrom') +
      ' ' +
      esc(mail.from_name || '') +
      ' (' +
      esc(mail.from_char || '') +
      ')';

    bodyEl.innerHTML =
      '<p style="font-family:var(--font-display);font-size:1.15rem;margin:0 0 12px;color:var(--accent)">' +
      esc(mail.subject || '') +
      '</p>' +
      '<div class="message-read">' +
      esc(mail.message || '') +
      '</div>' +
      '<div class="checkbox-row"><label><input type="checkbox" id="mk-unread"/> ' +
      esc(t('MarkAsUnreadLabel')) +
      '</label></div>';

    const unreadCb = bodyEl.querySelector('#mk-unread');
    unreadCb.checked = Number(mail.is_read) === 0;
    unreadCb.onchange = function () {
      api('MarkMailRead', {
        mailId: mail.id,
        read: !unreadCb.checked,
      }).then(function () {
        mail.is_read = unreadCb.checked ? 0 : 1;
      });
    };

    footerButtons([
      {
        label: t('BackButtonLabel'),
        onClick: function () {
          api('FetchMail', {}).then(function (r) {
            state.mails = (r && r.mails) || [];
            state.view = 'inbox';
            render();
          });
        },
      },
      {
        label: t('ReplyButtonLabel'),
        primary: true,
        onClick: function () {
          var code = String(mail.from_char || '').trim();
          state.compose = {
            postal: code,
            subject: 'Re: ' + (mail.subject || ''),
            message: '',
            contactName: mail.from_name || '',
          };
          state.view = 'compose';
          render();
        },
      },
      {
        label: t('DeleteMailButtonLabel'),
        danger: true,
        onClick: function () {
          api('DeleteMail', { mailId: mail.id }).then(function () {
            api('FetchMail', {}).then(function (r) {
              state.mails = (r && r.mails) || [];
              state.selectedMail = null;
              state.view = 'inbox';
              render();
            });
          });
        },
      },
    ]);
  }

  function renderCompose() {
    hdrTitle.textContent = t('SendPigeonHeader');
    hdrSub.textContent =
      t('SelectedContactLabel') +
      esc(state.compose.contactName || t('ManualRecipientLabel'));

    bodyEl.innerHTML =
      '<div class="field"><label>' +
      esc(t('PostalCodeLabel')) +
      '</label><input type="text" id="mf-postal" /></div>' +
      '<div class="field"><label>' +
      esc(t('SubjectPlaceholder')) +
      '</label><input type="text" id="mf-subj" /></div>' +
      '<div class="field"><label>' +
      esc(t('MessagePlaceholder')) +
      '</label><textarea id="mf-msg"></textarea></div>';

    var ip = bodyEl.querySelector('#mf-postal');
    var is = bodyEl.querySelector('#mf-subj');
    var im = bodyEl.querySelector('#mf-msg');
    ip.value = state.compose.postal || '';
    is.value = state.compose.subject || '';
    im.value = state.compose.message || '';

    footerButtons([
      {
        label: t('SelectRecipientButton'),
        onClick: function () {
          api('GetContacts', {}).then(function (r) {
            state.contacts = (r && r.contacts) || [];
            state.view = 'pickRecipient';
            render();
          });
        },
      },
      {
        label: t('SendMailButton'),
        primary: true,
        onClick: function () {
          state.compose.postal = ip.value.trim();
          state.compose.subject = is.value;
          state.compose.message = im.value;
          api('SendMail', {
            recipientPostalCode: state.compose.postal,
            subject: state.compose.subject,
            message: state.compose.message,
          }).then(function (r) {
            if (r && r.success) {
              fetch('https://' + resName() + '/spawnPigeon', {
                method: 'POST',
                body: '{}',
              }).catch(function () {});
              state.view = 'main';
              render();
            }
          });
        },
      },
      {
        label: t('BackButtonLabel'),
        ghost: true,
        onClick: function () {
          state.view = 'main';
          render();
        },
      },
    ]);
  }

  function renderContacts() {
    hdrTitle.textContent = t('ManageContactsHeader');
    hdrSub.textContent = '';
    if (!state.contacts.length) {
      bodyEl.innerHTML =
        '<div class="empty-hint">' + esc(t('NoContactsWarning')) + '</div>';
    } else {
      const wrap = document.createElement('div');
      wrap.className = 'mail-list';
      state.contacts.forEach(function (c) {
        const row = document.createElement('div');
        row.className = 'mail-row';
        row.style.cursor = 'default';
        const label =
          (c.displayName || c.postalCode || '') +
          ' (' +
          (c.postalCode || '') +
          ')';
        row.textContent = label;
        const rm = document.createElement('button');
        rm.type = 'button';
        rm.className = 'btn danger';
        rm.style.marginTop = '8px';
        rm.textContent = t('RemoveContactButton') + label;
        rm.onclick = function () {
          api('RemoveContact', { contactId: c.id }).then(function () {
            api('GetContacts', {}).then(function (r) {
              state.contacts = (r && r.contacts) || [];
              render();
            });
          });
        };
        row.appendChild(rm);
        wrap.appendChild(row);
      });
      bodyEl.appendChild(wrap);
    }
    footerButtons([
      {
        label: t('AddContactButton'),
        primary: true,
        onClick: function () {
          state.view = 'addContact';
          render();
        },
      },
      {
        label: t('BackButtonLabel'),
        onClick: function () {
          state.view = 'main';
          render();
        },
      },
    ]);
  }

  function renderAddContact() {
    hdrTitle.textContent = t('AddContactHeader');
    hdrSub.textContent = '';
    bodyEl.innerHTML =
      '<div class="field"><label>' +
      esc(t('PostalCodeLabel')) +
      '</label><input type="text" id="ac-code" /></div>' +
      '<div class="field"><label>' +
      esc(t('ContactAliasLabel')) +
      '</label><input type="text" id="ac-alias" /></div>';

    footerButtons([
      {
        label: t('SaveContactButton'),
        primary: true,
        onClick: function () {
          var code = bodyEl.querySelector('#ac-code').value;
          var alias = bodyEl.querySelector('#ac-alias').value;
          api('AddContact', {
            contactCode: code,
            contactAlias: alias,
          }).then(function () {
            api('GetContacts', {}).then(function (r) {
              state.contacts = (r && r.contacts) || [];
              state.view = 'contacts';
              render();
            });
          });
        },
      },
      {
        label: t('BackButtonLabel'),
        ghost: true,
        onClick: function () {
          state.view = 'contacts';
          render();
        },
      },
    ]);
  }

  var pickFilter = '';

  function renderPickRecipient() {
    hdrTitle.textContent = t('SelectRecipientHeader');
    hdrSub.textContent = '';

    bodyEl.innerHTML =
      '<div class="field"><label>' +
      esc(t('SearchRecipientsLabel')) +
      '</label><input type="search" id="pf-q" /></div>';
    var inp = bodyEl.querySelector('#pf-q');
    inp.value = pickFilter;
    inp.oninput = function () {
      pickFilter = inp.value;
      renderPickRecipient();
    };

    const low = pickFilter.toLowerCase();
    const wrap = document.createElement('div');
    wrap.className = 'mail-list';
    wrap.style.marginTop = '10px';

    var count = 0;
    var sorted = state.contacts.slice().sort(function (a, b) {
      var na = (a.displayName || a.postalCode || '').toLowerCase();
      var nb = (b.displayName || b.postalCode || '').toLowerCase();
      return na.localeCompare(nb);
    });

    sorted.forEach(function (c) {
      var label =
        (c.displayName || c.postalCode || '') +
        ' (' +
        (c.postalCode || '') +
        ')';
      var hay = label.toLowerCase();
      var skipSelf =
        (state.mailboxId &&
          String(c.mailboxId) === String(state.mailboxId)) ||
        (c.postalCode &&
          String(c.postalCode).toUpperCase() ===
            String(state.postalCode || '').toUpperCase());
      if (skipSelf) return;
      if (low && hay.indexOf(low) === -1) return;
      count++;
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'mail-row';
      btn.textContent = label;
      btn.onclick = function () {
        state.compose.postal = (c.postalCode || '').trim();
        state.compose.contactName = c.displayName || c.postalCode || '';
        pickFilter = '';
        state.view = 'compose';
        render();
      };
      wrap.appendChild(btn);
    });

    if (!count) {
      wrap.innerHTML =
        '<div class="empty-hint">' + esc(t('NoContactsWarning')) + '</div>';
    }
    bodyEl.appendChild(wrap);

    footerButtons([
      {
        label: t('BackButtonLabel'),
        onClick: function () {
          pickFilter = '';
          state.view = 'compose';
          render();
        },
      },
    ]);
  }

  function render() {
    clearPanels();
    var v = state.view;
    if (v === 'register') renderRegister();
    else if (v === 'main') renderMain();
    else if (v === 'inbox') renderInbox();
    else if (v === 'read') renderRead();
    else if (v === 'compose') renderCompose();
    else if (v === 'contacts') renderContacts();
    else if (v === 'addContact') renderAddContact();
    else if (v === 'pickRecipient') renderPickRecipient();
    else {
      bodyEl.innerHTML =
        '<div class="empty-hint">Unknown view</div>';
      footerButtons([{ label: 'Close', onClick: closeUi }]);
    }
  }

  window.addEventListener('message', function (event) {
    const d = event.data;
    if (!d || !d.action) return;

    if (d.action === 'open') {
      state.hasMailbox = !!d.hasMailbox;
      state.nearMailbox = !!d.nearMailbox;
      state.postalCode = d.postalCode || '';
      state.mailboxId = d.mailboxId;
      state.localeStrings = d.localeStrings || {};
      L = state.localeStrings;
      pickFilter = '';
      state.view = state.hasMailbox ? 'main' : 'register';
      shell.classList.remove('hidden');
      shell.classList.add('visible');
      render();
      return;
    }

    if (d.action === 'close') {
      shell.classList.add('hidden');
      shell.classList.remove('visible');
      return;
    }

    if (d.action === 'toast') {
      toast(d.message || '', d.type || 'info');
      return;
    }

    if (d.action === 'setLocales') {
      state.localeStrings = d.localeStrings || {};
      L = state.localeStrings;
    }
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
      closeUi();
    }
  });
})();
