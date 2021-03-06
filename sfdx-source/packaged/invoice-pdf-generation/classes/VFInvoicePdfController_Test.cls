@isTest
public class VFInvoicePdfController_Test {

    @TestSetup
    static void makeData(){
        Account a = TestDataFactory.CreateDefaultAccount();
        insert a;

        Invoice__c defaultInvoice = TestDataFactory.CreateInvoice(new Invoice__c(Account__c = a.Id));
        insert defaultInvoice;

        List<TimeEntry__c> tes = new List<TimeEntry__c>();
        tes.add(TestDataFactory.CreateTimeEntry(new TimeEntry__c(Account__c = a.Id)));
        tes.add(TestDataFactory.CreateTimeEntry(new TimeEntry__c(Account__c = a.Id)));
        insert tes;

        insert TestDataFactory.CreateDefaultOrganizationProfile();
    }
    
    @isTest
    static void getInvoice_NullId_EmptyInvoice() {
        // SETUP
        Test.setCurrentPage(Page.InvoicePdf);
        // VERIFY
        System.assertNotEquals(null, new VFInvoicePdfController().Invoice, 'Invoice');
        System.assertEquals(new Invoice__c(), new VFInvoicePdfController().Invoice.Record, 'Invoice.Record');
    }

    @isTest
    static void getInvoice_EmptyId_EmptyInvoice() {
        // SETUP
        Test.setCurrentPage(Page.InvoicePdf);
        ApexPages.currentPage().getParameters().put('Id', '');
        // VERIFY
        System.assertNotEquals(null, new VFInvoicePdfController().Invoice, 'Invoice');
        System.assertEquals(new Invoice__c(), new VFInvoicePdfController().Invoice.Record, 'Invoice.Record');
    }

    @isTest
    static void getInvoice_ValidId_EmptyInvoice() {
        // SETUP
        Invoice__c record = [SELECT Id FROM Invoice__c LIMIT 1];
        Test.setCurrentPage(Page.InvoicePdf);
        ApexPages.currentPage().getParameters().put('Id', record.Id);

        // VERIFY
        System.assertEquals(record.Id, new VFInvoicePdfController().Invoice.Record.Id, 'Invoice.Record.Id');
    }

    @isTest
    static void getRenderAs_ValueFromPageParam() {
        // SETUP
        Test.setCurrentPage(Page.InvoicePdf);
        ApexPages.currentPage().getParameters().put('renderAs', 'pdf');
        // VERIFY
        System.assertEquals('pdf', new VFInvoicePdfController().renderAs, 'renderAs');
    }

    @isTest
    static void getBankAccount_NoBankAccount_EmptyBankAccount() {
        // VERIFY
        System.assertEquals(new BankAccount__c(), new VFInvoicePdfController().BankAccount, 'BankAccount');
    }

    @isTest
    static void getBankAccount_HasBankAccount_RelatedBankAccount() {
        // SETUP
        BankAccount__c defaultBA = TestDataFactory.CreateBankAccount(new BankAccount__c(IsDefault__c = true));
        BankAccount__c otherBA = TestDataFactory.CreateBankAccount(new BankAccount__c(IsDefault__c = false, IBAN__c = 'DE000000000000000'));
        insert new List<BankAccount__c>{defaultBA, otherBA};

        OrganizationProfile__c orgProfile = [SELECT Id FROM OrganizationProfile__c LIMIT 1];
        orgProfile.BankAccount__c = defaultBA.Id;
        update orgProfile;

        // VERIFY
        System.assertEquals(defaultBA.Id, new VFInvoicePdfController().BankAccount.Id, 'BankAccount.Id');
        System.assertEquals(defaultBA.BankAccountOwner__c, new VFInvoicePdfController().BankAccount.BankAccountOwner__c, 'BankAccount.BankAccountOwner__c');
        System.assertEquals(defaultBA.BankName__c, new VFInvoicePdfController().BankAccount.BankName__c, 'BankAccount.BankName__c');
        System.assertEquals(defaultBA.IBAN__c, new VFInvoicePdfController().BankAccount.IBAN__c, 'BankAccount.IBAN__c');
    }

    @isTest
    static void getBankAccount_NonDefaultBankAccount_RelatedBankAccount() {
        // SETUP
        BankAccount__c defaultBA = TestDataFactory.CreateBankAccount(new BankAccount__c(IsDefault__c = true));
        BankAccount__c otherBA = TestDataFactory.CreateBankAccount(new BankAccount__c(IsDefault__c = false, IBAN__c = 'DE000000000000000'));
        insert new List<BankAccount__c>{defaultBA, otherBA};

        OrganizationProfile__c orgProfile = [SELECT Id FROM OrganizationProfile__c LIMIT 1];
        orgProfile.BankAccount__c = otherBA.Id;
        update orgProfile;

        // VERIFY
        System.assertEquals(otherBA.Id, new VFInvoicePdfController().BankAccount.Id, 'BankAccount.Id');
        System.assertEquals(otherBA.BankAccountOwner__c, new VFInvoicePdfController().BankAccount.BankAccountOwner__c, 'BankAccount.BankAccountOwner__c');
        System.assertEquals(otherBA.BankName__c, new VFInvoicePdfController().BankAccount.BankName__c, 'BankAccount.BankName__c');
        System.assertEquals(otherBA.IBAN__c, new VFInvoicePdfController().BankAccount.IBAN__c, 'BankAccount.IBAN__c');
    }

    @isTest
    static void getLanguage_NoParam_ValueFromInvoiceReturned() {
        // SETUP
        Invoice__c record = [SELECT Id,PdfLanguage__c FROM Invoice__c LIMIT 1];
        record.PdfLanguage__c = 'en_DE';
        update record;
        Test.setCurrentPage(Page.InvoicePdf);
        ApexPages.currentPage().getParameters().put('Id', record.Id);
        
        // VERIFY
        System.assertEquals('en_DE', new VFInvoicePdfController().Language, 'Language');
    }

    @isTest
    static void getLanguage_Param_OverwriteValueFromInvoice() {
        // SETUP
        Invoice__c record = [SELECT Id,PdfLanguage__c FROM Invoice__c LIMIT 1];
        record.PdfLanguage__c = 'en_DE';
        update record;
        Test.setCurrentPage(Page.InvoicePdf);
        ApexPages.currentPage().getParameters().put('Id', record.Id);
        ApexPages.currentPage().getParameters().put('lang', 'de_CH');
        
        // VERIFY
        System.assertEquals('de_CH', new VFInvoicePdfController().Language, 'Language');
    }

    @isTest
    static void getOrgProfile_NoParam_NoDefaultProfileExists_EmptyProfileGenerated() {
        // SETUP
        delete [SELECT Id FROM OrganizationProfile__c];
        Test.setCurrentPage(Page.InvoicePdf);

        // ACTION
        OrganizationProfile__c op = new VFInvoicePdfController().OrgProfile;

        // VERIFY
        System.assertEquals(new OrganizationProfile__c(), op, 'OrgProfile');
    }

    @isTest
    static void getOrgProfile_NoParam_DefaultProfileExists_DefaultProfileReturned() {
        // SETUP
        insert TestDataFactory.CreateOrganizationProfile(new OrganizationProfile__c(IsDefault__c = false, Name = 'Non Default Test 2'));
        Test.setCurrentPage(Page.InvoicePdf);
        // ACTION
        OrganizationProfile__c op = new VFInvoicePdfController().OrgProfile;
        // VERIFY
        OrganizationProfile__c expectedProfile = [SELECT Id FROM OrganizationProfile__c WHERE IsDefault__c = true LIMIT 1];
        System.assertEquals(expectedProfile.Id, op.Id, 'OrgProfile');
    }

    @isTest
    static void getOrgProfile_NoParam_ProfileInInvoice_InvoiceProfileReturned() {
        // SETUP
        OrganizationProfile__c newProfile = TestDataFactory.CreateOrganizationProfile(
            new OrganizationProfile__c(IsDefault__c = false, OrganizationName__c = 'Other Company GmbH')
        );
        insert newProfile;

        Invoice__c record = [SELECT Id,PdfLanguage__c FROM Invoice__c LIMIT 1];
        record.OrganizationProfile__c = newProfile.Id;
        update record;

        Test.setCurrentPage(Page.InvoicePdf);
        ApexPages.currentPage().getParameters().put('Id', record.Id);

        // ACTION
        OrganizationProfile__c op = new VFInvoicePdfController().OrgProfile;

        // VERIFY
        System.assertEquals(newProfile.Id, op.Id, 'OrgProfile');
    }

    @isTest
    static void getOrgProfile_InvalidParam_DefaultProfileExists_DefaultProfileReturned() {
        // SETUP
        Test.setCurrentPage(Page.InvoicePdf);
        ApexPages.currentPage().getParameters().put('orgProfileId', 'test-id');
        // ACTION
        OrganizationProfile__c op = new VFInvoicePdfController().OrgProfile;
        // VERIFY
        OrganizationProfile__c expectedProfile = [SELECT Id FROM OrganizationProfile__c LIMIT 1];
        System.assertEquals(expectedProfile.Id, op.Id, 'OrgProfile');
    }

    @isTest
    static void getOrgProfile_ValidParam_DefaultProfileExists_RequestedProfileReturned() {
        // SETUP
        OrganizationProfile__c newProfile = TestDataFactory.CreateOrganizationProfile(
            new OrganizationProfile__c(IsDefault__c = false, OrganizationName__c = 'Other Company GmbH')
        );
        insert newProfile;

        Test.setCurrentPage(Page.InvoicePdf);
        ApexPages.currentPage().getParameters().put('orgProfileId', newProfile.Id);

        // ACTION
        OrganizationProfile__c op = new VFInvoicePdfController().OrgProfile;

        // VERIFY
        System.assertEquals(newProfile.Id, op.Id, 'OrgProfile');
    }

    @isTest
    static void getDisplayTimesheet_NoParam_ValueFromInvoiceReturned() {
        // SETUP
        Invoice__c record = [SELECT Id,PdfLanguage__c FROM Invoice__c LIMIT 1];
        record.PdfRenderTimesheet__c = true;
        update record;

        List<TimeEntry__c> tes = [SELECT Id FROM TimeEntry__c];
        for (TimeEntry__c te : tes) te.Invoice__c = record.Id;
        update tes;

        // ACTION
        Test.setCurrentPage(Page.InvoicePdf);
        ApexPages.currentPage().getParameters().put('Id', record.Id);

        // VERIFY
        System.assertEquals(true, new VFInvoicePdfController().DisplayTimesheet, 'DisplayTimesheet');
    }

    @isTest
    static void getDisplayTimesheet_ParamTrue_OverrideValueFromInvoice() {
        // SETUP
        Invoice__c record = [SELECT Id,PdfLanguage__c FROM Invoice__c LIMIT 1];
        record.PdfRenderTimesheet__c = false;
        update record;

        List<TimeEntry__c> tes = [SELECT Id FROM TimeEntry__c];
        for (TimeEntry__c te : tes) te.Invoice__c = record.Id;
        update tes;

        // ACTION
        Test.setCurrentPage(Page.InvoicePdf);
        ApexPages.currentPage().getParameters().put('Id', record.Id);
        ApexPages.currentPage().getParameters().put('displayTimesheet', 'true');
        
        // VERIFY
        System.assertEquals(true, new VFInvoicePdfController().DisplayTimesheet, 'DisplayTimesheet');
        ApexPages.currentPage().getParameters().put('displayTimesheet', 'false');
        System.assertEquals(false, new VFInvoicePdfController().DisplayTimesheet, 'DisplayTimesheet');
    }

    @isTest
    static void getDisplayTimesheet_ParamTrue_NoTimeEntries_False() {
        // SETUP
        Invoice__c record = [SELECT Id,PdfLanguage__c FROM Invoice__c LIMIT 1];
        record.PdfRenderTimesheet__c = false;
        update record;
        delete [SELECT Id FROM TimeEntry__c];
        Test.setCurrentPage(Page.InvoicePdf);

        // ACTION
        ApexPages.currentPage().getParameters().put('Id', record.Id);
        ApexPages.currentPage().getParameters().put('displayTimesheet', 'true');
        
        // VERIFY
        System.assertEquals(false, new VFInvoicePdfController().DisplayTimesheet, 'DisplayTimesheet');
        ApexPages.currentPage().getParameters().put('displayTimesheet', 'false');
        System.assertEquals(false, new VFInvoicePdfController().DisplayTimesheet, 'DisplayTimesheet');
    }
}
