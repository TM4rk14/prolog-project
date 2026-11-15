:- ensure_loaded(player).
:- ensure_loaded(trans).
:- use_module(library(random)).
%lesz egy loop ami vegig megy a kulcsos listan es megnezi hogy meg letezik e 
%ha igen akkor szamol neki egy random valid iranyt ami  nem az ahonnan jott 
moveKeys([],_,_,_,_,_,_).

moveKeys([KeyObj|Rest],Matrix,Window,CellWidth,CellHeight,EntityList,GateList):- 
  (
    object(KeyObj)
  -> getNextDirection(KeyObj,Matrix,DX,DY),
    try_move(KeyObj,DX,DY,Matrix,Window,CellWidth,CellHeight,EntityList,GateList)
  ; true
  ),
  moveKeys(Rest,Matrix,Window,CellWidth,CellHeight,EntityList,GateList).

%kiszamolom az uj iranyt 
getNextDirection(KeyObj,Matrix,DX,DY) :-
    %lekerdezem az ismert informaciokat a jelenlegi helyzetrol 
    get(KeyObj,attribute,posX,X),
    get(KeyObj,attribute,posY,Y),
    get(KeyObj,attribute,pastX,PastX),
    get(KeyObj,attribute,pastY,PastY),

    %kimerem a valid lepesek parjait
    findall([CurrX,CurrY],
      (member([CurrX,CurrY],[[0,1],[0,-1],[1,0],[-1,0]]),
      NewX is X+CurrX,
      NewY is Y+CurrY,
      (NewX=\= PastX; NewY =\= PastY),
      getCell(NewX,NewY,Matrix,Value),
      (\+ member(Value,[1,2,3,4,5,9])) 
      ),
      ValidPaths
    ),

    %megnezem ha zsakutcaba ert akkor forduljon vissza
    (ValidPaths\=[]
    -> random_member([DX,DY],ValidPaths)
    ;
      %visszafordulok es a past mostmar a jelenlegi lesz 
      DX is PastX-X,
      DY is PastY-Y
    ),

    send(KeyObj,attribute,pastX,X),
    send(KeyObj,attribute,pastY,Y).
