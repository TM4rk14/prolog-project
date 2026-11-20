 :- use_module(library(lists)).
:- use_module(library(pce)).
generateMatrix(N,M,Edges,FinalMatrix) :-
    GridN is (2*N)+1,
    GridM is (2*M)+1,
    %Csoportositok a sor alapjan, majd a betweenel erem el hogy M-szer lefusson, s
    %generalis a maplist-el 1-eseket a jelenlegi sorba
    %maplist-> vegrehajt egy predikatumot a lista minden elemen
    findall(Row,(between(1,GridM,_),length(Row,GridN),maplist(=(1),Row)),BaseMatrix),
    setCenters(BaseMatrix,N,M,TempMatrix),
    setConnection(TempMatrix,Temp2Matrix,Edges),
    setShadow(Temp2Matrix,N,M,FinalMatrix).

% beallitom a kozeppontokat
setCenters(BaseMatrix,N,M,OutMatrix) :-
    %a findall-t es a betweeneket hasznalom egy dupla for helyettesitesere
    %az eredmenyeket pedig amik a kozeppontok elmentem
    findall([CX,CY],
      ( between(1,N,X),
        between(1,M,Y),
        CX is 2*X,
        CY is 2*Y
      ), Centers),
      segedSetCenters(Centers,BaseMatrix,OutMatrix).

%megkapja a kozepponokat es 0-ra allitja a kozeppontokat a matrixban
%minden kozepont az szabad akarcsak az OutMatrix
%megallasi feltel ha nincs tobb kozeppont
segedSetCenters([],BaseMatrix,BaseMatrix) :-!.
segedSetCenters([[X,Y]|RestCenters],BaseMatrix,OutMatrix) :-
    setCell(X,Y,0,BaseMatrix,TempMatrix),
    segedSetCenters(RestCenters,TempMatrix,OutMatrix).

%beallitom az elek szerint amin bejartam a maze-t az utakat a matrixban
setConnection(BaseMatrix,BaseMatrix,[]) :-!.
setConnection(BaseMatrix,OutMatrix,[[X1,Y1]-[X2,Y2]|Edges]) :-
    RoadX is X1+X2,
    RoadY is Y1+Y2,
    setCell(RoadX,RoadY,0,BaseMatrix,TempMatrix),
    setConnection(TempMatrix,OutMatrix,Edges).


%legeneralom a findall es betweenekkel minden lehetseges koordinata part a matrixbol
setShadow(Matrix,N,M,OutMatrix) :-
    GridN is 2*N+1,
    GridM is 2*M+1,
    findall([X,Y],
    (between(1,GridN,X),
      NewM is GridM-1,
     between(1,NewM,Y)
    ),Coordinates),
    segedSetShadow(Coordinates,Matrix,OutMatrix).
%
%Beteszem a 2eseket is amik a 3Ds effecket fokjak adni a palyanak a megfelelo helyekre
segedSetShadow([],OutMatrix,OutMatrix):-!.
segedSetShadow([[X,Y]|RestCoordinates],BaseMatrix,OutMatrix) :-
  %csak olyan helyre teszek 2 ahol fal van es alatta egybol ut
    getCell(X,Y,BaseMatrix,CurrentValue),
    (
      CurrentValue =:= 1,
      NextY is Y+1,
      getCell(X,NextY,BaseMatrix,NextValue),
      NextValue =:= 0
      ->(
        setCell(X,Y,2,BaseMatrix,TempMatrix),
        segedSetShadow(RestCoordinates,TempMatrix,OutMatrix)
      );segedSetShadow(RestCoordinates,BaseMatrix,OutMatrix)
    ).

%segedpredikatum ami beallitja a matrix adott cellajat egy adott ertekre
setCell(J,I,NewValue,Matrix,OutMatrix) :-
  %nth1 egy beepitett predikatum ami egy elemet vesz ki egy listabol
  %kiveszem az I sort j
  nth1(I,Matrix,NeededRow,RestMatrix),
  %kiveszem a J elemet
  nth1(J,NeededRow,_,RestRow),
  %beallitom az ertekre
  nth1(J,NewRow,NewValue,RestRow),
  nth1(I,OutMatrix,NewRow,RestMatrix).

%segedpredikatum egy elem lekerdezesere
getCell(X,Y,Matrix,CurrentValue) :-
    nth1(Y,Matrix,NeededRow),
    nth1(X,NeededRow,CurrentValue).

%seged predikatumok amik a kirajzolasban fognak segiteni
draw_row([],_,_,_,_).
draw_row([CurrentRow|RestRow],Y,CellWidth,CellHeight,Window) :-
    draw_column(CurrentRow,1,Y,CellWidth,CellHeight,Window),
    NextY is Y +1,
    draw_row(RestRow,NextY,CellWidth,CellHeight,Window).

draw_column([],_,_,_,_,_).
draw_column([CurrentValue|Rest],X,Y,CellWidth,CellHeight,Window) :-
    % most megkapom a kezdopontokat ahonnan fogok rajzolni
    PX is (X-1)*CellWidth,
    PY is (Y-1)*CellHeight,

    draw_cell(Window,CurrentValue,PX,PY,CellWidth,CellHeight),
      NextX is X +1,
    draw_column(Rest,NextX,Y,CellWidth,CellHeight,Window).

cell_color(0,colour(black)).
cell_color(1,colour(dodger_blue)).
cell_color(2,colour(navy)).
%segedpredikatumok amik a megadott spirtott visszaadjak a megfelelo kodra
grabImage(3, Img):- new(Img, image('sprites/Copperdoor.png')).
grabImage(4, Img):- new(Img, image('sprites/Golddoor.png')).
grabImage(5, Img):- new(Img, image('sprites/Diamonddoor.png')).
grabImage(6, Img):- new(Img, image('sprites/Copperkey.png')).
grabImage(7, Img):- new(Img, image('sprites/Goldkey.png')).
grabImage(8, Img):- new(Img, image('sprites/Diamondkey.png')).
grabImage(9, Img):- new(Img, image('sprites/EndPoint.png')).


%kiegeszitese a cella rajzolasnak az ajtok es a kulcsok miat
draw_cell(Window, Index, PX, PY, CellWidth, CellHeight) :-
    Index > 2,
    !,
    new(Bg, image(@nil, CellWidth, CellHeight, pixmap)),
    send(Bg, fill, colour(black)), %
    send(Window, display, new(_, bitmap(Bg)), point(PX, PY)),
    KeyX is PX + (CellWidth // 2) - 16,
    KeyY is PY + (CellHeight // 2) - 16,
    grabImage(Index,Img),
    send(Window, display, new(_, bitmap(Img)), point(KeyX, KeyY)).

% 1. kulon eset (fal 3D előlapja éles peremmel)
draw_cell(Window, 2, PX, PY, CellWidth, CellHeight) :- !,
    % Perem magassaga
    EdgeHeight is max(2, CellHeight // 4),
    BottomHeight is CellHeight - EdgeHeight,
    %kiszamolom a saroknak es a rendes falnak a koordinatait
    PY_Bottom is PY + EdgeHeight,

    %edge kirajzolassa
    new(TopImg, image(@nil, CellWidth, EdgeHeight, pixmap)),
    send(TopImg, fill, colour(dodger_blue)),
    send(Window, display, new(_, bitmap(TopImg)), point(PX, PY)),

    %maradek fal kiirasa
    new(BotImg, image(@nil, CellWidth, BottomHeight, pixmap)),
    send(BotImg, fill, colour(navy)),
    send(Window, display, new(_, bitmap(BotImg)), point(PX, PY_Bottom)).

%1,0hoz megfelelo kirajzolas
draw_cell(Window, Val, PX, PY, CellWidth, CellHeight) :-
    cell_color(Val, Color),
    new(Img, image(@nil, CellWidth, CellHeight, pixmap)),
    send(Img, fill, Color),
    send(Window, display, new(_, bitmap(Img)), point(PX, PY)).
