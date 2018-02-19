drop table if exists PitcherCareers;

create table PitcherCareers(
playerID text primary key,
nameLast text,
nameFirst text,
W integer,
L integer,
IPouts integer,
ER integer,
HR integer,
BB integer,
SO integer,
num_allstar integer,
num_cy_youngs integer,
num_mvps integer,
inducted text
);

insert into PitcherCareers select a.playerID as playerID, nameLast, nameFirst, W, L, IPouts,
ER, HR, BB, SO, num_allstar, num_cy_youngs, num_mvps, inducted
from ((((
select Pitching.playerID as playerID, nameLast, nameFirst, sum(W) as W, sum(L) as L,
sum(IPouts) as IPouts, sum(ER) as ER, sum(HR) as HR, sum(BB) as BB,
sum(SO) as SO
from Players inner join Pitching on Players.playerID = Pitching.playerID
group by Pitching.playerID) as a left join (
select playerID, count(*) as num_allstar
from AllStars
group by playerID) as b on a.playerID = b.playerID) as c left join (
select playerID, count(*) as num_cy_youngs
from CyYoungs
group by playerID) as d on c.playerID = d.playerID) as e left join (
select playerID, count(*) as num_mvps
from MVPs
group by playerID) as f on e.playerID = f.playerID) as g left join (
select distinct playerID, max(inducted) as inducted
from HallOfFame
group by playerID) as h on g.playerID = h.playerID;

update PitcherCareers
set num_allstar = 0
where num_allstar is null;

update PitcherCareers
set num_cy_youngs = 0
where num_cy_youngs is null;

update PitcherCareers
set num_mvps = 0
where num_mvps is null;

update PitcherCareers
set inducted = "N"
where not (playerID = "kershcl01" or playerID = "greinza01" or playerID = "sabatcc01" or playerID = "verlaju01" or playerID = "hamelco01" or playerID = "hernafe02" or playerID = "scherma01" or playerID = "colonba01" or playerID = "lestejo01" or playerID = "wainwad01" or playerID = "salech01" or playerID = "lackejo0" or playerID = "weaveje02" or playerID = "priceda01" or playerID = "bumgama01" or playerID = "cainma01" or playerID = "cuetojo01" or playerID = "shielja02" or playerID = "klubeco01" or playerID = "gonzagi01" or playerID = "santaer01" or playerID = "strasst01" or playerID = "arroybr01" or playerID = "dickera01" or playerID = "quintjo01" or playerID = "gallayo01" or playerID = "arrieja01" or playerID = "jimenub01" or playerID = "sanchan01" or playerID = "zimmejo02" or playerID = "peavyja01" or playerID = "kazmisc01" or playerID = "linceti01" or playerID = "danksjo01" or playerID = "hudsoti01" or playerID = "buehrma01" or playerID = "harenda01" or playerID = "zitoba01" or playerID = "burneaj01" or playerID = "wolfra02" or playerID = "leecl02" or playerID = "beckejo02" or playerID = "kurodhi01" or playerID = "pennybr01" or playerID = "hallaro01" or playerID = "pettian01" or playerID = "oswalro01" or playerID = "garcifr03" or playerID = "lowede01" or playerID = "lillyte01" or playerID = "johnsjo09" or playerID = "dempsry01" or playerID = "garlajo01" or playerID = "santajo02" or playerID = "zambrca01" or playerID = "moyerja01" or playerID = "carpech01" or playerID = "hernali01" or playerID = "millwke01" or playerID = "sheetbe01") and inducted is null;