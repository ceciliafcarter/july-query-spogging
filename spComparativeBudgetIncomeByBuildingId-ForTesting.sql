


--SELECT * FROM dbo.ComplianceDocument

--UPDATE dbo.ComplianceDocument
--SET    CamlInnerQuery='<Where><And><Eq><FieldRef Name=''ContentType'' /><Value Type=''Text''>UP Property Financial Document</Value></Eq><Eq><FieldRef Name=''Financial_x0020_Category'' /><Value Type=''Text''>AR Delinquency Lists</Value></Eq></And></Where><OrderBy><FieldRef Name=''Created'' Ascending=''False'' /></OrderBy>'
--WHERE ComplianceDocumentId=1


--SELECT * FROM dbo.tblCRMBuildingTenants

--EXECUTE [dbo].[spGetAgedDelinquencies] 4997, 12,199,0

DECLARE 	@PeriodYear varchar(6),    @Entity varchar(6)
SET @PeriodYear ='2014'
SET @Entity ='087301'

Select
--BLDG.BLDGNAME,
A.Month,
A.Year,
A.Period,
A.EntityID,
--Sum(A.ActualExpense) as 'Actual Expense',
--Sum(A.BudgetedExpense) as 'Budget Expense',
Sum(A.ActualIncome) as 'ActualIncome',
Sum(A.BudgetedIncome) as 'BudgetIncome'
--Sum(A.ActualNOI) as 'Actual NOI',
--Sum(A.BudgetedNOI) as 'Budget NOI'
 
From
(
            Select
            Left(P.PERIOD,4) as 'Year',
            Right(P.PERIOD,2) as 'Month',
            P.PERIOD, --G.ACCTNAME,G.ACCTNUM,
            P.ENTITYID,
            SUM(CASE WHEN LEFT(J.ACCTNUM,3)='MR6' THEN J.AMT
                                                        ELSE 0 END) as ActualExpense,
            0 as BudgetedExpense,
            SUM(CASE WHEN LEFT(J.ACCTNUM,3)='MR5' THEN J.AMT
                                                        ELSE 0 END)*-1 as ActualIncome,
            0 as BudgetedIncome,
            SUM(CASE WHEN LEFT(J.AcctNum,3)='MR5' or LEFT(J.AcctNum,3)='MR6' or LEFT(J.AcctNum,3)='MR7' THEN J.AMT
                                                        ELSE 0 END)*-1 as ActualNOI,
            0 as BudgetedNOI
            From
            Period P (nolock)
            --Left join JOURNAL J (nolock) on P.ENTITYID=J.ENTITYID and P.Period=J.Period
            join JOURNAL J (nolock) on P.ENTITYID=J.ENTITYID and P.Period=J.Period
            Join GACC G (nolock) on G.ACCTNUM=J.ACCTNUM
			join BLDG b (nolock) on p.ENTITYID = b.ENTITYID
            Where
            P.ENTITYID=@Entity
            and Left(P.PERIOD,4) = @PeriodYear
            --and P.PERIOD='201506'
            Group by
            Left(P.PERIOD,4),
            Right(P.PERIOD,2),
            P.PERIOD,
            --G.ACCTNAME,G.ACCTNUM,
            P.ENTITYID
 
      Union All
 
            Select
            Left(P.PERIOD,4) as 'Year',
            Right(P.PERIOD,2) as 'Month',
            P.PERIOD, --G.ACCTNAME,G.ACCTNUM,
            P.ENTITYID,
            SUM(CASE WHEN LEFT(J.ACCTNUM,3)='MR6' THEN J.AMT
                                                        ELSE 0 END) as ActualExpense,
            0 as BudgetedExpense,
            SUM(CASE WHEN LEFT(J.ACCTNUM,3)='MR5' THEN J.AMT
                                                        ELSE 0 END)*-1 as ActualIncome,
            0 as BudgetedIncome,
            SUM(CASE WHEN LEFT(J.AcctNum,3)='MR5' or LEFT(J.AcctNum,3)='MR6' or LEFT(J.AcctNum,3)='MR7' THEN J.AMT
                                                        ELSE 0 END)*-1 as ActualNOI,
            0 as BudgetedNOI
            From
            Period P (nolock)
            --Left join JOURNAL J (nolock) on P.ENTITYID=J.ENTITYID and P.Period=J.Period
            join GHIS J (nolock) on P.ENTITYID=J.ENTITYID and P.Period=J.Period
            Join GACC G (nolock) on G.ACCTNUM=J.ACCTNUM            
			join BLDG b (nolock) on p.ENTITYID = b.ENTITYID
            Where
            P.ENTITYID=@Entity
            and Left(P.PERIOD,4) = @PeriodYear
            --and P.PERIOD='201505'
            Group by
            Left(P.PERIOD,4),
            Right(P.PERIOD,2),
            P.PERIOD,
            --G.ACCTNAME,G.ACCTNUM,
            P.ENTITYID
 
      Union ALL
 
            Select
            Left(B.PERIOD,4) as 'Year',
            Right(B.PERIOD,2) as 'Month',
            B.PERIOD, --G.ACCTNAME,G.ACCTNUM,
            B.ENTITYID,--B.BUDTYPE,
            0 as ActualExpense,
            SUM(CASE WHEN LEFT(B.AcctNum,3)='MR6' THEN B.ACTIVITY
                                                        ELSE 0 END) as BudgetedExpense,
            0 as ActualIncome,
            SUM(CASE WHEN LEFT(B.AcctNum,3)='MR5' THEN B.ACTIVITY
                                                        ELSE 0 END)*-1 as BudgetedIncome,
            0 as ActualNOI,
            SUM(CASE WHEN LEFT(B.AcctNum,3)='MR6' or LEFT(B.AcctNum,3)='MR7' or LEFT(B.AcctNum,3)='MR5' THEN B.ACTIVITY
                                                        ELSE 0 END)*-1 as BudgetedNOI
            From
            BUDGETS B (nolock)
            --Left join JOURNAL J (nolock) on P.ENTITYID=J.ENTITYID and P.Period=J.Period
            Join GACC G (nolock) on G.ACCTNUM=B.ACCTNUM
            Left Join Period P (nolock) on P.ENTITYID=B.ENTITYID and P.Period=B.Period
            Where
            B.ENTITYID=@Entity
            and Left(B.PERIOD,4) = @PeriodYear
            --and P.PERIOD='201505'
            and b.BUDTYPE='STD'
            and b.BASIS='A'
            --and b.ACTIVITY=109 --Specific amount search
            Group by
            Left(B.PERIOD,4),
            Right(B.PERIOD,2),
            B.PERIOD,
            --G.ACCTNAME,G.ACCTNUM,
            B.ENTITYID
) A, BLDG
Where
      BLDG.ENTITYID=@Entity
Group by
      BLDG.BLDGNAME,
      A.Year,
      A.Month,
      A.Period,
      A.EntityID
