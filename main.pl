:- use_module(library(random)).
:- use_module(library(pce)).
:- ensure_loaded(trans).
:- ensure_loaded(player).
:- ensure_loaded(kulcsMovement).
movelist(M) :- 
  M = [[1,0],[0,1],[-1,0],[0,-1]].


onEdge([X,Y], N, M) :-
    X =:= 1;
    Y =:= 1;
    X =:= N;
    Y =:= M.

%Megnezem hogy van e atjaras ket cella kozott a path-ben
%kell a rajzolashoz
atmegy(Cell1,Cell2,Edges) :-
    (
      member(Cell1-Cell2,Edges);
      member(Cell2-Cell1,Edges)
    ).

%mikor ures a queue megallunk
bfs([], _, _, UtolsoKivettSzelso, UtolsoKivettSzelso,_,_).

bfs([CurrCell | RestQueue], Visited, Edges, EddigiLegjobb, Eredmeny,N,M) :-

    %kigyutjuk a szomszedokat, amiknel meg nem jartunk
    findall(Neighbor, (
        atmegy(CurrCell, Neighbor, Edges),
        \+ member(Neighbor, Visited)
    ), UjSzomszedok),
    % megjeloljuk meglatogatottkent a szomszedokat
    append(UjSzomszedok, Visited, NewVisited),
    % a queue vegere pusholjuk a szomszedokat
    append(RestQueue, UjSzomszedok, NewQueue),
    % az uj queue-val megyunk tovabb,ha a jelenleg kivett szelso, az lesz az utolso meglatogatott szelso, ellenkezo esetben megyunk tovabb az eddigi legjobb talalattal
    (onEdge(CurrCell, N, M) ->
        bfs(NewQueue, NewVisited, Edges, CurrCell, Eredmeny, N, M);
        bfs(NewQueue, NewVisited, Edges, EddigiLegjobb, Eredmeny, N, M)
    ).

%megtalalja az utat az elso es masodik parameter kozott(start,end)
findPath(End, End, _, CurrPath, FinalPath) :- % ha start = end akkor megerkeztunk, visszadjuk a jelenlegi utat
    reverse(CurrPath, FinalPath), !.

findPath(Curr, End, Edges, CurrPath, FinalPath) :-
    atmegy(Curr, Next, Edges), %szomszedok
    \+ member(Next, CurrPath), %meg nem jartunk itt a jelenlegi uton
    findPath(Next, End, Edges, [Next | CurrPath], FinalPath).

partialBfs([], Visited, _, Visited).
partialBfs([Curr | RestQueue], Visited, Edges, Reachable) :-
    findall(Neighbor, (
        atmegy(Curr, Neighbor, Edges),
        \+ member(Neighbor, Visited)
    ), UjSzomszedok),
    append(UjSzomszedok, Visited, NewVisited),
    append(RestQueue, UjSzomszedok, NewQueue),
    partialBfs(NewQueue, NewVisited, Edges, Reachable).



  %itt jon a dfs resze
dfs_koordinatakkal([CurrentNodeX,CurrentNodeY], Visited,VisitedOut,Edges,EdgesOut,N,M) :- 
  movelist(MoveList),
  (
    %veszem a kovi szomszedott ami megfelelo
    nextAdjacentNode(CurrentNodeX,CurrentNodeY,NextX,NextY,N,M,MoveList),
    \+ member([NextX,NextY],Visited)
    ->NewEdge=[CurrentNodeX,CurrentNodeY]-[NextX,NextY],
      %teszek ket Acc tipusu argumentudom hogy tudjam mibe elmenteni
      %hogy mit lattam azon az agon
      %ezzel megyek tovabb az egyik agon
      dfs_koordinatakkal([NextX,NextY],[[NextX,NextY]|Visited],VisitedAcc,[NewEdge|Edges],EdgesAcc,N,M),

      %meghivom ujra hogy megnezzem hogy van e meg at ami utan visszaerek ide a masik agrol
      dfs_koordinatakkal([CurrentNodeX,CurrentNodeY],VisitedAcc,VisitedOut,EdgesAcc,EdgesOut,N,M);

      %ha mar nincstobb ag akkor visszaadom a kapott ertekeket az 
      %output argumentumokba
      VisitedOut=Visited,
      EdgesOut=Edges
  ).



nextAdjacentNode(CurrentX,CurrentY,NextX,NextY,N,M,MoveList) :-  
    %teszek egy permutationt hogy ne mindig ugyan ugy nezze a szomszedokat nezzel 
    %randomabb lesz a maze 
    random_permutation(MoveList,ShuffledMoveList),
    member([NextOffsetX,NextOffsetY],ShuffledMoveList),
    NextX is CurrentX + NextOffsetX,
    NextY is CurrentY + NextOffsetY,
    NextX>=1,
    NextX=<N,
    NextY>=1,
    NextY=<M.


%megallasi feltel
rajz([], _, _, _,N,M,_) :- !.
%kirajzolom a vonalakat amik az utak a bejarashoz
rajz([[XP1,YP1]-[XP2,YP2] | Rest], CurrentWindow, CellWidth, CellHeight,N,M,Edges) :- 
    CX1 is (XP1 - 1) * CellWidth + (CellWidth / 2),
    CY1 is (YP1 - 1) * CellHeight + (CellHeight / 2),
    CX2 is (XP2 - 1) * CellWidth + (CellWidth / 2),
    CY2 is (YP2 - 1) * CellHeight + (CellHeight / 2),
    X_Left   is (XP1 - 1) * CellWidth,
    X_Right  is XP1 * CellWidth,
    Y_Top    is (YP1 - 1) * CellHeight,
    Y_Bottom is YP1 * CellHeight,
    %felso vonal
    %feltetel -> 
    (YP1=:=1->send(CurrentWindow,display,new(_,line(X_Left,Y_Top,X_Right,Y_Top)));true),

    %bal kulso fal
    (XP1=:=1->send(CurrentWindow,display,new(_,line(X_Left,Y_Top,X_Left,Y_Bottom)));true),

    %also fal <-> ha racs vagy ha nem lefele mentem 
    NextYP2 is YP1 + 1,
    ((YP1=:=M ; \+ atmegy([XP1,YP1],[XP1,NextYP2],Edges))->send(CurrentWindow,display,new(_,line(X_Left,Y_Bottom,X_Right,Y_Bottom)));true),

    %jobb oldali fal <--->
    NextXP2 is XP1 +1,
    ((XP1=:=N; \+ atmegy([XP1,YP1],[NextXP2,YP1],Edges))->send(CurrentWindow,display,new(_,line(X_Right,Y_Top,X_Right,Y_Bottom)));true),
    
    %send(CurrentWindow, display, new(_, line(CX1, CY1, CX2, CY2))),
    % send(CurrentWindow,display,new(_,line(CX1,CY1,CX2,CY2))),
    rajz(Rest, CurrentWindow, CellWidth, CellHeight,N,M,Edges).


setStartPosition([X, Y], MatrixIn,MatrixOut) :-
    MatrixX is 2 * X,
    MatrixY is 2 * Y,
    setCell(MatrixX, MatrixY, 5, MatrixIn, MatrixOut).

setEndPosition([X, Y], MatrixIn,MatrixOut) :-
    MatrixX is 2 * X,
    MatrixY is 2 * Y,
    setCell(MatrixX, MatrixY, 9, MatrixIn, MatrixOut).

calculateGatePositions(Path,Gate1,Gate2,Gate3,Edges):-
    length(Path,Len),
    Quarter is Len div 4,
    Half is Len div 2,
    ThreeQuarter is (Len*3) div 4,
    %kivesszuk a megfelelo elemeket a tombbol
    nth1(Quarter,Path,[X11,Y11]),
    Quarter1 is Quarter+1,
    nth1(Quarter1,Path,[X12,Y12]),

    nth1(Half,Path,[X21,Y21]),
    Half1 is Half+1,
    nth1(Half1,Path,[X22,Y22]),

    nth1(ThreeQuarter,Path,[X31,Y31]),
    ThreeQuarter1 is ThreeQuarter+1,
    nth1(ThreeQuarter1,Path,[X32,Y32]),

    (member([X11,Y11]-[X12,Y12],Edges)->
    Gate1 = [X11,Y11]-[X12,Y12];
    Gate1 = [X12,Y12]-[X11,Y11]),

   ( member([X21,Y21]-[X22,Y22], Edges) ->
    Gate2 = [X21,Y21]-[X22,Y22];
    Gate2 = [X22,Y22]-[X21,Y21]),

(    member([X31,Y31]-[X32,Y32], Edges) ->
    Gate3 = [X31,Y31]-[X32,Y32];
    Gate3 = [X32,Y32]-[X31,Y31]).

setEdge(BaseMatrix, OutMatrix, GateCode, [X1,Y1]-[X2,Y2]) :- 
  RoadX is X1 + X2,
  RoadY is Y1 + Y2,
  setCell(RoadX, RoadY, GateCode, BaseMatrix, OutMatrix). 

setGatePositions(BaseMatrix,OutMatrix,Gate1,Gate2,Gate3):-
    setEdge(BaseMatrix, Matrix2, 3, Gate1), 
    setEdge(Matrix2, Matrix3, 4, Gate2),
    setEdge(Matrix3, OutMatrix, 5, Gate3).

%akkor zsakutca ha 1 szomszed van
zsakutca(Cella, Edges) :-
    findall(N, atmegy(Cella, N, Edges), Szomszedok),
    length(Szomszedok, 1).

kulcsGeneralas(StartPoint, ZoneEdges, PartialEdges, Kulcs) :-
    findall(C, (
        member(C, ZoneEdges),
        C \= StartPoint,             % nem a kezdopontba rakjuk
        zsakutca(C, PartialEdges)   % csak zsakutcaba rakunk kulcsot
    ), Zsakutcak),
    random_permutation(Zsakutcak, Shuffled), %megkeverjuk random
    Shuffled = [Kulcs | _]. %az elsot kivesszuk a kulcsnak

setKulcsPositions(BaseMatrix,OutMatrix,X1,Y1,X2,Y2,X3,Y3):-
    setCell(X1, Y1, 4, BaseMatrix, Matrix2),
    setCell(X2, Y2, 4, Matrix2, Matrix3),
    setCell(X3, Y3, 4, Matrix3, OutMatrix).

generate(InputWidth, InputHeight, N, M) :-
    % labirintus generalas
    dfs_koordinatakkal([1,1], [[1,1]], Visited, [], Edges, N, M),

    % Kezdo es vegpont szamitas
    bfs([[1,1]], [[1,1]], Edges, [1,1], Start, N, M),
    bfs([Start], [Start], Edges, Start, End, N, M),

    %kapuk elhelyezese
    findPath(Start,End,Edges,[],Path), %legrovidebb ut start es end kozott(dfs mert csak egy ut van mert spanning tree)
    calculateGatePositions(Path,Gate1,Gate2,Gate3,Edges),


    %kulcsok elhelyezese
    %kivesszuk a kapukat az elek kozul, ezzel 4 kulon feszitofa jon letre
    subtract(Edges, [Gate1,Gate2,Gate3], PartialEdges),

    length(Path, Len),
    Quarter1 is (Len div 4) + 1,
    nth1(Quarter1, Path, StartZone2),%masodik zonaban van
    Half1 is (Len div 2) + 1,
    nth1(Half1, Path, StartZone3),%harmadik zonaban van

    partialBfs([Start],[Start],PartialEdges,Zone1), %megkapjuk a csucsokat a zonaban
    kulcsGeneralas(Start,Zone1,PartialEdges,Kulcs1), %kivalasztunk 1 zsakutcat a kulcsnak

    partialBfs([StartZone2],[StartZone2],PartialEdges,Zone2), %megkapjuk a csucsokat a zonaban
    kulcsGeneralas(StartZone2,Zone2,PartialEdges,Kulcs2), %kivalasztunk 1 zsakutcat a kulcsnak

    partialBfs([StartZone3],[StartZone3],PartialEdges,Zone3), %megkapjuk a csucsokat a zonaban
    kulcsGeneralas(StartZone3,Zone3,PartialEdges,Kulcs3), %kivalasztunk 1 zsakutcat a kulcsnak

    Kulcs1 = [X11,Y11],
    Kulcs2 = [X22,Y22],
    Kulcs3 = [X33,Y33],

    % a helyukre szorozzuk a kulcsokat
    X1 is X11 * 2,
    Y1 is Y11 * 2,
    X2 is X22 * 2,
    Y2 is Y22 * 2,
    X3 is X33 * 2,
    Y3 is Y33 * 2,


    % legeneraljuk a matrixot az elek alapjan
    generateMatrix(N, M, PartialEdges, Matrix1),
    %feljegyezzuk a kapukat
    setGatePositions(Matrix1,Matrix3,Gate1,Gate2,Gate3), % uj
    setEndPosition(End,Matrix3,FinalMatrix), % uj


    % ablak meretezes
    length(FinalMatrix, GridM),
    FinalMatrix = [FirstRow| _],
    length(FirstRow, GridN),
    CellWidth is InputWidth // GridN,
    CellHeight is InputHeight // GridM,
    WinWidth is CellWidth * GridN,
    WinHeight is CellHeight * GridM,
    % ablak letrehozasa es rajzolas
    new(W, picture('XPCE')),
    send(W, size, size(WinWidth, WinHeight)),
    %kiveszem a start poziciot amit a bfs-el legeneraltam majd bescalelem hogy jo legyen a matrixon 
    getPointFromList(Start,StartX,StartY),
    ScaledStartX is StartX*2,
    ScaledStartY is StartY*2,
    draw_row(FinalMatrix, 1, CellWidth, CellHeight, W),
    create_player(W,CellWidth,CellHeight,1,[ScaledStartX,ScaledStartY],PlayerObj),
  

    %megcsinalom a kulcsokat 
    create_player(W,CellWidth,CellHeight,6,[X1,Y1],KeyObj1), % 
    create_player(W,CellWidth,CellHeight,7,[X2,Y2],KeyObj2), % 
    create_player(W,CellWidth,CellHeight,8,[X3,Y3],KeyObj3), 
    KeyObjList=[KeyObj1,KeyObj2,KeyObj3], 
    EntityList=[PlayerObj|KeyObjList],

    %megcsinalom a kapukat 
    maplist(getGateCoords,[Gate1,Gate2,Gate3],GateList),
    setup_controls(W,FinalMatrix,CellWidth,CellHeight,PlayerObj,EntityList,GateList),
    
    %timer ami idonkent elinditja a kulcsok mozgasat
    new(T, timer(0.4, message(@prolog, moveKeys, prolog(KeyObjList), prolog(FinalMatrix), W, CellWidth, CellHeight, prolog(EntityList), prolog(GateList)))),
    send(W, attribute, key_timer, T), 
    send(T, start),
    send(W, done_message, and(message(T, stop), message(T, free), message(W, destroy))),
    
    send(W, open),
    send(W?frame, keyboard_focus, W).
    % ablak megnyitas

getPointFromList([PosX,PosY],PosX,PosY).

getGateCoords([X1,Y1]-[X2,Y2],[RealX,RealY]):- 
    RealX is X1 + X2,
    RealY is Y1 + Y2.
