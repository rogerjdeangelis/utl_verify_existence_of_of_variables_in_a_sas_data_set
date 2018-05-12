Verify the Existence of Variables in a Table

see at end of message

One datastep and hash solution
from Paul Dorfman

see
https://tinyurl.com/yb9euycm
https://github.com/rogerjdeangelis/utl_verify_existence_of_of_variables_in_a_sas_data_set

Same result in WPS and SAS


INPUT
=====

 WORK.META total obs=7

  Obs    _NAME_

   1     DX
   2     NAME           ** IN SASHELP.CLASS
   3     SEX            ** IN SASHELP.CLASS
   4     LOCDESCR
   5     REM_CURRID
   6     REM_ID3
   7     REM_RECIPNO


 SASHELP.CLASS

    Variables in Creation Order

   #    Variable    Type    Len

   1    NAME        Char      8
   2    SEX         Char      1
   3    AGE         Num       8
   4    HEIGHT      Num       8
   5    WEIGHT      Num       8



 EXAMPLE OUTPUT
 --------------

  MISSING VARIABLES

   WORK.WANT_MISSING total obs=5

   Obs    _NAME_

    1     DX
    2     LOCDESCR
    3     REM_CURRID
    4     REM_ID3
    5     REM_RECIPNO

  COMMON VARIABLES

   WORK.WANT_COMMON total obs=2

   Obs    _NAME_

    1      NAME
    2      SEX


PROCESS
=======

  options validvarname=upcase;  ** can be important - icose to use upcase;
  * note 0 ob transpose;
  proc transpose data=sashelp.class(obs=0 keep=_character_) out=clsXpo;
    var _all_;
  run;quit;

  * the variables you are missing;;
  proc sql;

    create table want_missing as

    select upcase(_name_) from meta
    except
    select upcase(_name_) from clsXpo

  ;quit;

 * variAbles in common;
 proc sql;
   create

     table want_common as

     select upcase(_name_) from meta
     intersect
     select upcase(_name_) from clsXpo
 ;quit;

OUTPUT:

   WORK.WANT_MISSING total obs=5

   Obs    _NAME_

    1     DX
    2     LOCDESCR
    3     REM_CURRID
    4     REM_ID3
    5     REM_RECIPNO

  COMMON VARIABLES

   WORK.WANT_COMMON total obs=2

   Obs    _NAME_

    1      NAME
    2      SEX

*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

options validvarname=upcase;
data meta;
input _name_ $32.;
cards4;
DX
NAME
SEX
LOCDESCR
REM_CURRID
REM_ID3
REM_RECIPNO
;;;;
run;quit;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_) | | |_| | |_| | (_) | | | |
|___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

  options validvarname=upcase;  ** impportant;

  * note this is a 0 obs transpose;
  proc transpose data=sashelp.class(obs=0 keep=_character_) out=clsXpo;
     var _all_;
  run;quit;

  * the variables you are missing;;
  proc sql;

    create table want_missing as

    select * from meta
    except
    select * from clsXpo

  ;quit;

 * variAbles in common;
 proc sql;
   create

     table want_common as

     select _name_ from meta
     intersect
     select _name_ from clsXpo
 ;quit;


%utl_submit_wps64('
libname wrk sas7bdat "%sysfunc(pathname(work))";
libname hlp sas7bdat "C:\progra~1\SASHome\SASFoundation\9.4\core\sashelp";
 options validvarname=upcase;
 proc transpose data=hlp.class(obs=0 keep=_character_) out=clsXpo;
    var _all_;
 run;quit;

 * the variables you are missing;;
 proc sql;

   create table want_missing as

   select upcase(_name_) from wrk.meta
   except
   select upcase(_name_)from clsXpo

 ;quit;

* variables in common;
proc sql;
  create

    table want_common as

    select upcase(_name_) from wrk.meta
    intersect
    select upcase(_name_) from clsXpo
;quit;
run;quit;
');

One datastep and hash solution
from Paul Dorfman

Paul Dorfman
sashole@bellsouth.net


data expected_vars;
length name $32;
   infile cards missover;
      input name $ type;
cards;
agency 2
dx 2
name 2
locdescr 2
rem_currid 2
rem_id3 2
rem_recipno 2
;
run;

data received ;
  retain agency      "agency"
         dx          "dx"
         name        "name"
         locdescr    "locdescr"
     /* rem_currid  "rem_currid"  */
         rem_id3     "rem_id3"
         rem_recipno "rem_recipno"
         more        "more"
  ;

run ;

%let rn = _%sysfunc(md5(#),$hex30.) ;
%put &=rn;

data not_found (keep=&rn found rename=(&rn=name)) ;
  set received ;
  array cc _char_ ;
  do until (z) ;
    found = 0 ;
    set expected_vars (rename=(name=&rn)) end = z ;
    do over cc ;
      if &rn = vname(cc) then found = 1 ;
    end ;
    if found then continue ;
    output ;
    fail = 1 ;
  end ;
  call symputx ("success", not fail) ;
run ;

%put &=success ;


Thanks, Roger.

Explanation of one step solution

Need to ensure (sort of) that the ID var in Expected_Vars, Name, is
not in Received. Using md5 (underscore + 31 random hex characters, md5
argument doesn't matter) or just a string of 32 underscores is quick and
dirty. Of course, we can look at what's in Received and rename Name on
input to something else. But that wouldn't be one step ;).

data _null_ ;
  set received ;
  array cc _char_ ;
  dcl hash h(dataset:"expected_vars( rename=(name=&rn))") ;
  h.definekey ("&rn") ;
  h.definedone () ;
  do over cc ;
    _n_ + (h.check(key:vname(cc)) = 0) ;
  end ;
  call symputx ("success", _n_-1 = n) ;
  set expected_vars(rename=(name=& rn)) nobs=n ;
  stop ;
run ;

%put &=success ;






