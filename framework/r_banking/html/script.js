let bankData = {
    accounts: [],
    transactions: [],
    playerName: '',
    currentSection: 'dashboard',
    currentTransactionType: 'deposit',
    transferStep: 1,
    currentHistoryPage: 1,
    totalHistoryPages: 1
};

const elements = {};

function initializeElements() {
    const container = MODULE_CONTAINER || document;

    elements.container = container.querySelector('#bankContainer') || document.getElementById('bankContainer');
    elements.userName = container.querySelector('#userName') || document.getElementById('userName');
    elements.closeBtn = container.querySelector('#closeBtn') || document.getElementById('closeBtn');
    elements.navBtns = container.querySelectorAll('.nav-btn') || document.querySelectorAll('.nav-btn');
    elements.sections = container.querySelectorAll('.section') || document.querySelectorAll('.section');
    elements.accountsList = container.querySelector('#accountsList') || document.getElementById('accountsList');
    elements.recentTransactions = container.querySelector('#recentTransactions') || document.getElementById('recentTransactions');
    elements.transactionAccount = container.querySelector('#transactionAccount') || document.getElementById('transactionAccount');
    elements.transactionAmount = container.querySelector('#transactionAmount') || document.getElementById('transactionAmount');
    elements.transactionDescription = container.querySelector('#transactionDescription') || document.getElementById('transactionDescription');
    elements.submitTransaction = container.querySelector('#submitTransaction') || document.getElementById('submitTransaction');
    elements.transactionTypeBtns = container.querySelectorAll('.transaction-type-btn') || document.querySelectorAll('.transaction-type-btn');
    elements.fromAccount = container.querySelector('#fromAccount') || document.getElementById('fromAccount');
    elements.toAccount = container.querySelector('#toAccount') || document.getElementById('toAccount');
    elements.transferAmount = container.querySelector('#transferAmount') || document.getElementById('transferAmount');
    elements.transferDescription = container.querySelector('#transferDescription') || document.getElementById('transferDescription');
    elements.transferNextBtn = container.querySelector('#transferNextBtn') || document.getElementById('transferNextBtn');
    elements.transferPrevBtn = container.querySelector('#transferPrevBtn') || document.getElementById('transferPrevBtn');
    elements.confirmTransfer = container.querySelector('#confirmTransfer') || document.getElementById('confirmTransfer');
    elements.transferSteps = container.querySelectorAll('.transfer-step') || document.querySelectorAll('.transfer-step');
    elements.historyAccount = container.querySelector('#historyAccount') || document.getElementById('historyAccount');
    elements.historyType = container.querySelector('#historyType') || document.getElementById('historyType');
    elements.historyTableBody = container.querySelector('#historyTableBody') || document.getElementById('historyTableBody');
    elements.prevPage = container.querySelector('#prevPage') || document.getElementById('prevPage');
    elements.nextPage = container.querySelector('#nextPage') || document.getElementById('nextPage');
    elements.paginationInfo = container.querySelector('#paginationInfo') || document.getElementById('paginationInfo');
}

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.module === 'bank') {
        console.log('Message du loader reçu:', JSON.stringify(data));

        switch (data.action) {
            case 'init':
                initializeBankUI(data.data);
                break;

            case 'update':
                updateBankUI(data.data);
                break;

            case 'show':
                showBankUI();
                break;

            case 'hide':
                hideBankUI();
                break;
        }
        return;
    }
});

function initializeBankUI(data) {
    console.log('Initialisation de l\'interface bancaire avec:', JSON.stringify(data));

    initializeElements();

    bankData.accounts = data.accounts || [];
    bankData.transactions = data.transactions || [];
    bankData.playerName = data.playerName || 'Utilisateur';

    console.log('Données chargées:', JSON.stringify({
        accounts: bankData.accounts.length,
        transactions: bankData.transactions.length,
        playerName: bankData.playerName
    }));

    if (elements.userName) {
        elements.userName.textContent = bankData.playerName;
    }

    clearAllInputs();

    populateAccountsList();
    populateAccountSelects();
    populateRecentTransactions();
    showSection('dashboard');

    initializeEventListeners();

    showBankUI();
}

function updateBankUI(data) {
    if (data.action === 'show') {
        bankData.accounts = data.accounts || bankData.accounts;
        bankData.transactions = data.transactions || bankData.transactions;
        bankData.playerName = data.playerName || bankData.playerName;

        if (elements.userName && bankData.playerName) {
            elements.userName.textContent = bankData.playerName;
        }

        clearAllInputs();
        showSection('dashboard');

        populateAccountsList();
        populateAccountSelects();
        populateRecentTransactions();
        showBankUI();
        return;
    }

    if (data.action === 'hide') {
        hideBankUI();
        return;
    }

    if (data.action === 'transactionsLoaded') {
        console.log('JavaScript reçu transactionsLoaded:', JSON.stringify(data));
        populateTransactionHistory(data);
        return;
    }

    if (data.action === 'balanceUpdated') {
        const account = bankData.accounts.find(acc => acc.account_number === data.accountNumber);
        if (account) {
            account.balance = data.balance;
            populateAccountsList();
            populateAccountSelects();
        }
        return;
    }

    if (data.action === 'transactionCompleted') {
        if (bankData.currentSection === 'transactions') {
            elements.transactionAmount.value = '';
            elements.transactionDescription.value = '';
        }

        if (bankData.currentSection === 'transfer') {
            elements.transferAmount.value = '';
            elements.transferDescription.value = '';
            elements.toAccount.value = '';
            showTransferStep(1);
        }

        return;
    }

    bankData.accounts = data.accounts || bankData.accounts;
    bankData.transactions = data.transactions || bankData.transactions;

    populateAccountsList();
    populateAccountSelects();
    populateRecentTransactions();
}

function showBankUI() {
    if (MODULE_CONTAINER) {
        MODULE_CONTAINER.style.display = 'block';
    } else if (elements.container) {
        elements.container.style.display = 'flex';
    }
}

function hideBankUI() {
    if (MODULE_CONTAINER) {
        MODULE_CONTAINER.style.display = 'none';
    } else if (elements.container) {
        console.log("element trouvé")
        elements.container.style.display = 'none';
    }
}

function clearAllInputs() {
    // Nettoie tous les champs de saisie
    if (elements.transactionAmount) elements.transactionAmount.value = '';
    if (elements.transactionDescription) elements.transactionDescription.value = '';
    if (elements.transferAmount) elements.transferAmount.value = '';
    if (elements.transferDescription) elements.transferDescription.value = '';
    if (elements.toAccount) elements.toAccount.value = '';

    // Reset des sélecteurs de compte
    if (elements.transactionAccount) elements.transactionAccount.value = '';
    if (elements.fromAccount) elements.fromAccount.value = '';
    if (elements.historyAccount) elements.historyAccount.value = '';
    if (elements.historyType) elements.historyType.value = '';

    // Reset du type de transaction par défaut
    bankData.currentTransactionType = 'deposit';
    if (elements.transactionTypeBtns) {
        elements.transactionTypeBtns.forEach(btn => {
            btn.classList.remove('active');
            if (btn.getAttribute('data-type') === 'deposit') {
                btn.classList.add('active');
            }
        });
    }

    // Reset du transfert à l'étape 1
    bankData.transferStep = 1;
    if (elements.transferSteps && elements.transferSteps.length > 0) {
        showTransferStep(1);
    }

    // Reset de la pagination
    bankData.currentHistoryPage = 1;
    bankData.totalHistoryPages = 1;

    // Met à jour le texte du bouton de transaction
    if (elements.submitTransaction) {
        const span = elements.submitTransaction.querySelector('span');
        if (span) {
            span.textContent = 'Confirmer le dépôt';
        }
    }
}

function formatCurrency(amount) {
    return new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 2
    }).format(amount);
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('fr-FR', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }).format(date);
}


function validateAmount(amount) {
    const num = parseFloat(amount);
    if (isNaN(num) || num <= 0) {
        showNotification('Le montant doit être un nombre positif', 'error');
        return false;
    }
    if (num > 999999999) {
        showNotification('Le montant est trop élevé', 'error');
        return false;
    }
    return true;
}

function showSection(sectionName) {
    elements.sections.forEach(section => {
        section.classList.remove('active');
    });

    elements.navBtns.forEach(btn => {
        btn.classList.remove('active');
    });

    document.getElementById(sectionName).classList.add('active');
    document.querySelector(`[data-section="${sectionName}"]`).classList.add('active');

    bankData.currentSection = sectionName;

    if (sectionName === 'history') {
        console.log("Section historique active")
        loadTransactionHistory();
    }
}

function populateAccountsList() {
    if (!elements.accountsList) return;

    elements.accountsList.innerHTML = '';

    bankData.accounts.forEach(account => {
        const accountElement = document.createElement('div');
        accountElement.className = 'account-item';
        accountElement.innerHTML = `
            <div class="account-info">
                <div class="account-type">
                    <i class="fas fa-user"></i>
                    <span>${account.account_name || 'Compte Personnel'}</span>
                </div>
                <div class="account-number">#${account.account_number}</div>
            </div>
            <div class="account-balance">
                <span class="balance-amount">${formatCurrency(account.balance || 0)}</span>
            </div>
        `;
        elements.accountsList.appendChild(accountElement);
    });
}

function populateAccountSelects() {
    const selects = [elements.transactionAccount, elements.fromAccount, elements.historyAccount];

    selects.forEach(select => {
        if (!select) return;

        const currentValue = select.value;
        select.innerHTML = '<option value="">Sélectionner un compte</option>';

        bankData.accounts.forEach(account => {
            const option = document.createElement('option');
            option.value = account.account_number;
            option.textContent = `${account.account_name || 'Compte'} (#${account.account_number}) - ${formatCurrency(account.balance || 0)}`;
            select.appendChild(option);
        });

        if (currentValue) {
            select.value = currentValue;
        }
    });
}

function populateRecentTransactions() {
    if (!elements.recentTransactions) return;

    elements.recentTransactions.innerHTML = '';

    const recentTx = bankData.transactions.slice(0, 5);

    if (recentTx.length === 0) {
        elements.recentTransactions.innerHTML = '<p class="no-transactions">Aucune transaction récente</p>';
        return;
    }

    recentTx.forEach(tx => {
        const txElement = document.createElement('div');
        txElement.className = 'transaction-item';

        let icon, typeText, amountClass;

        switch (tx.transaction_type) {
            case 'deposit':
                icon = 'fas fa-arrow-down';
                typeText = 'Dépôt';
                amountClass = 'positive';
                break;
            case 'withdraw':
                icon = 'fas fa-arrow-up';
                typeText = 'Retrait';
                amountClass = 'negative';
                break;
            case 'transfer_in':
                icon = 'fas fa-arrow-right';
                typeText = 'Virement reçu';
                amountClass = 'positive';
                break;
            case 'transfer_out':
                icon = 'fas fa-arrow-right';
                typeText = 'Virement envoyé';
                amountClass = 'negative';
                break;
            default:
                icon = 'fas fa-exchange-alt';
                typeText = 'Transaction';
                amountClass = '';
        }

        txElement.innerHTML = `
            <div class="transaction-icon ${tx.transaction_type}">
                <i class="${icon}"></i>
            </div>
            <div class="transaction-details">
                <div class="transaction-type">${typeText}</div>
                <div class="transaction-time">${formatDate(tx.created_at)}</div>
            </div>
            <div class="transaction-amount ${amountClass}">
                ${amountClass === 'negative' ? '-' : '+'}${formatCurrency(Math.abs(tx.amount))}
            </div>
        `;

        elements.recentTransactions.appendChild(txElement);
    });
}

function loadTransactionHistory(page = 1) {
    const accountNumber = elements.historyAccount?.value || '';
    const transactionType = elements.historyType?.value || '';

    // Si aucun compte n'est pas sélectionné, prendre le premier compte disponible
    let selectedAccount = accountNumber;
    if (!selectedAccount && bankData.accounts && bankData.accounts.length > 0) {
        selectedAccount = bankData.accounts[0].account_number;
        if (elements.historyAccount) {
            elements.historyAccount.value = selectedAccount;
        }
    }

    if (!selectedAccount) {
        console.log('Aucun compte disponible pour l\'historique');
        return;
    }

    let finalTransactionType = transactionType;
    if (!transactionType || transactionType === '') {
        finalTransactionType = 'all';
    }

    bankData.currentHistoryPage = page;

    console.log("loadTransactionHistory - Account:", selectedAccount, "Type:", finalTransactionType, "Page:", page);

    fetch(`https://${GetParentResourceName()}/getTransactions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            accountNumber: selectedAccount,
            transactionType: finalTransactionType,
            page: page,
            limit: 10
        })
    });
}

function populateTransactionHistory(data) {
    console.log('populateTransactionHistory appelée avec:', JSON.stringify(data));

    if (!elements.historyTableBody) {
        console.log('elements.historyTableBody non trouvé');
        return;
    }

    elements.historyTableBody.innerHTML = '';

    if (!data.transactions || data.transactions.length === 0) {
        console.log('Aucune transaction dans les données');
        elements.historyTableBody.innerHTML = '<tr><td colspan="5">Aucune transaction trouvée</td></tr>';
        return;
    }

    console.log('Nombre de transactions à afficher:', data.transactions.length);

    data.transactions.forEach(tx => {
        const row = document.createElement('tr');

        let typeText;
        switch (tx.transaction_type) {
            case 'deposit': typeText = 'Dépôt'; break;
            case 'withdraw': typeText = 'Retrait'; break;
            case 'transfer_in': typeText = 'Virement reçu'; break;
            case 'transfer_out': typeText = 'Virement envoyé'; break;
            default: typeText = 'Transaction';
        }

        row.innerHTML = `
            <td>${formatDate(tx.created_at)}</td>
            <td><span class="transaction-badge ${tx.transaction_type}">${typeText}</span></td>
            <td>${tx.description || '-'}</td>
            <td class="${tx.transaction_type.includes('out') || tx.transaction_type === 'withdraw' ? 'negative' : 'positive'}">
                ${tx.transaction_type.includes('out') || tx.transaction_type === 'withdraw' ? '-' : '+'}${formatCurrency(Math.abs(tx.amount))}
            </td>
            <td>${formatCurrency(tx.balance_after)}</td>
        `;

        elements.historyTableBody.appendChild(row);
    });

    bankData.currentHistoryPage = data.page || 1;
    bankData.totalHistoryPages = data.totalPages || 1;

    if (elements.paginationInfo) {
        elements.paginationInfo.textContent = `Page ${bankData.currentHistoryPage} sur ${bankData.totalHistoryPages}`;
    }

    if (elements.prevPage) {
        elements.prevPage.disabled = bankData.currentHistoryPage <= 1;
    }

    if (elements.nextPage) {
        elements.nextPage.disabled = bankData.currentHistoryPage >= bankData.totalHistoryPages;
    }
}

function showTransferStep(step) {
    elements.transferSteps.forEach(stepEl => {
        stepEl.classList.remove('active');
    });

    document.querySelector(`[data-step="${step}"]`).classList.add('active');

    if (step === 1) {
        elements.transferPrevBtn.style.display = 'none';
        elements.transferNextBtn.style.display = 'inline-flex';
        elements.confirmTransfer.style.display = 'none';
    } else if (step === 2) {
        elements.transferPrevBtn.style.display = 'inline-flex';
        elements.transferNextBtn.style.display = 'none';
        elements.confirmTransfer.style.display = 'inline-flex';

        const fromAccountData = bankData.accounts.find(acc => acc.account_number === elements.fromAccount.value);
        document.getElementById('confirmFromAccount').textContent = fromAccountData ?
            `${fromAccountData.account_name} (#${fromAccountData.account_number})` : '-';
        document.getElementById('confirmToAccount').textContent = elements.toAccount.value || '-';
        document.getElementById('confirmAmount').textContent = formatCurrency(parseFloat(elements.transferAmount.value) || 0);
        document.getElementById('confirmDescription').textContent = elements.transferDescription.value || '-';
    }

    bankData.transferStep = step;
}

function initializeEventListeners() {
    if (elements.navBtns) {
        elements.navBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                const section = btn.getAttribute('data-section');
                showSection(section);
            });
        });
    }

    if (elements.closeBtn) {
        elements.closeBtn.addEventListener('click', () => {
            fetch(`https://${GetParentResourceName()}/closeBank`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            }).then(hideBankUI());
        });
    }

    if (elements.transactionTypeBtns) {
        elements.transactionTypeBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                elements.transactionTypeBtns.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                bankData.currentTransactionType = btn.getAttribute('data-type');

                const submitText = bankData.currentTransactionType === 'deposit' ? 'dépôt' : 'retrait';
                if (elements.submitTransaction) {
                    const span = elements.submitTransaction.querySelector('span');
                    if (span) {
                        span.textContent = `Confirmer le ${submitText}`;
                    }
                }
            });
        });

    }

    if (elements.submitTransaction) {
        elements.submitTransaction.addEventListener('click', () => {
            const accountNumber = elements.transactionAccount.value;
            const amount = parseFloat(elements.transactionAmount.value);
            const description = elements.transactionDescription.value;

            if (!accountNumber) {
                showNotification('Veuillez sélectionner un compte', 'error');
                return;
            }

            if (!validateAmount(amount)) return;

            const eventName = bankData.currentTransactionType === 'deposit' ? 'deposit' : 'withdraw';

            fetch(`https://${GetParentResourceName()}/${eventName}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    accountNumber: accountNumber,
                    amount: amount,
                    description: description || `${bankData.currentTransactionType === 'deposit' ? 'Dépôt' : 'Retrait'} via interface`
                })
            });
        });
    }

    if (elements.transferNextBtn) {
        elements.transferNextBtn.addEventListener('click', () => {
            const fromAccount = elements.fromAccount.value;
            const toAccount = elements.toAccount.value;
            const amount = parseFloat(elements.transferAmount.value);

            if (!fromAccount || !toAccount || !validateAmount(amount)) {
                showNotification('Veuillez remplir tous les champs requis', 'error');
                return;
            }

            if (fromAccount === toAccount) {
                showNotification('Impossible de transférer vers le même compte', 'error');
                return;
            }

            showTransferStep(2);
        });
    }

    if (elements.transferPrevBtn) {
        elements.transferPrevBtn.addEventListener('click', () => {
            showTransferStep(1);
        });
    }

    if (elements.confirmTransfer) {
        elements.confirmTransfer.addEventListener('click', () => {
            const fromAccount = elements.fromAccount.value;
            const toAccount = elements.toAccount.value;
            const amount = parseFloat(elements.transferAmount.value);
            const description = elements.transferDescription.value;

            fetch(`https://${GetParentResourceName()}/transfer`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    fromAccountNumber: fromAccount,
                    toAccountNumber: toAccount,
                    amount: amount,
                    description: description || 'Virement via interface'
                })
            });
        });
    }

    if (elements.historyAccount) {
        elements.historyAccount.addEventListener('change', loadTransactionHistory);
    }

    if (elements.historyType) {
        elements.historyType.addEventListener('change', loadTransactionHistory);
    }

    const actionBtns = (MODULE_CONTAINER || document).querySelectorAll('.action-btn');
    actionBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            if (btn.classList.contains('deposit-btn')) {
                showSection('transactions');
                const depositBtn = (MODULE_CONTAINER || document).querySelector('[data-type="deposit"]');
                if (depositBtn) depositBtn.click();
            } else if (btn.classList.contains('withdraw-btn')) {
                showSection('transactions');
                const withdrawBtn = (MODULE_CONTAINER || document).querySelector('[data-type="withdraw"]');
                if (withdrawBtn) withdrawBtn.click();
            } else if (btn.classList.contains('transfer-btn')) {
                showSection('transfer');
            }
        });
    });

    const viewAllBtn = (MODULE_CONTAINER || document).querySelector('.view-all-btn');
    if (viewAllBtn) {
        viewAllBtn.addEventListener('click', () => {
            showSection('history');
        });
    }

    if (elements.prevPage) {
        elements.prevPage.addEventListener('click', () => {
            if (bankData.currentHistoryPage > 1) {
                loadTransactionHistory(bankData.currentHistoryPage - 1);
            }
        });
    }

    if (elements.nextPage) {
        elements.nextPage.addEventListener('click', () => {
            if (bankData.currentHistoryPage < bankData.totalHistoryPages) {
                loadTransactionHistory(bankData.currentHistoryPage + 1);
            }
        });
    }
}

document.addEventListener('DOMContentLoaded', function () {
    initializeElements();
    initializeEventListeners();
});

document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closeBank`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(hideBankUI());
    }
});