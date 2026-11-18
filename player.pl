:- ensure_loaded(trans).
%ez a fuggveny letrehoz entitasokat koztuk a playert es kulcsot a megadott argumentum alapjan, ez a Form 
create_player(Window,CellWidth,CellHeight,Form,[StartX,StartY],PlayerObj) :- 
    %beallitom a kezdokoordinatakat
    PlayerX is (StartX-1)*CellWidth,
    PlayerY is (StartY-1)*CellHeight,

    %kornek a szukseges informaciok
    PlayerHeight  is CellHeight//2,
    PlayerWidth is CellWidth//2,

    %betoltom a player spritott 
    (Form=:=1 % uj
    -> new(RawImg, image('player.xpm')),
       get(RawImg, scale, size(CellWidth, CellHeight), ScaledImg),
       new(PlayerObj,bitmap(ScaledImg))

       %kiveszem a megfelelo kulcs spritetott a folderbol
    ;  grabImage(Form, RawKeyImg), %
       get(RawKeyImg, scale, size(CellWidth, CellHeight), ScaledKeyImg),
       new(PlayerObj,bitmap(ScaledKeyImg))
    ),
    %megadok alapatributumot a playerobjektumnak hogy mindig szamon tudjam tartani a helyet
    %es a kulcsok szamat
    send(PlayerObj,attribute,posX,StartX),
    send(PlayerObj,attribute,posY,StartY),
    (
      Form =:=1
    -> send(PlayerObj,attribute,collectedKeys,0)
    ; send(PlayerObj,attribute,pastX,StartX),
      send(PlayerObj,attribute,pastY,StartY)
    ), 
        %beallitom a kezdopontra 
    send(Window,display,PlayerObj,point(PlayerX,PlayerY)).

try_move(PlayerObj,DX,DY,Matrix,Window,CellWidth,CellHeight,EntityList,GateList) :- 
    get(PlayerObj,attribute,posX,CurrentX),
    get(PlayerObj,attribute,posY,CurrentY),
    
    %uj pozicio
    NewX is CurrentX+DX,
    NewY is CurrentY+DY,


    getCell(NewX,NewY,Matrix,Value),
    (
      %if-else aggal megnezem hogy lehetseges e a mozgas
      %ha igen mozgatom a karaktert ha nem akkor csak true-t teritek vissza
     ( member(Value,[0,9]) % uj
     ; % kulonleges eset amikor kaput van akkor megnezem hogy van e eleg kuhlcsom hozza 
       %ez azert jo mivel igy nem kell a matriban megvaltoztatnom az erteket es egy outputmatrixal dolgoznom
       %
       member(Value,[3,4,5]),
       get(PlayerObj,attribute,collectedKeys,Ertek),
       nth1(GateIndex,GateList,[NewX,NewY]),
       Ertek>=GateIndex

     )
     ->
        %beallitom a jelenlegi poziciot a matrixban
        send(PlayerObj,attribute,posX,NewX),
        send(PlayerObj,attribute,posY,NewY),

        %kiszamolom az uj poziciot a kepernyon
        NewPX is (NewX-1)*CellWidth,
        NewPY is (NewY-1)*CellHeight,
        send(PlayerObj,position,point(NewPX,NewPY)),
        checkCollision(PlayerObj,EntityList),
        ( Value =:= 9
        ->( get(Window,attribute,key_timer,T),
            object(T)
          ->
            send(T,stop),
            free(T)
          ;true
          ),
          send(Window,destroy)
        ; true 
          )
      ;true
    ).

% megnezem az ooszes olyen obj-et ami nem egyezik a jelenlegivel ami mozgott 
% es megnezem hogy egy mezon vannak e ekkor pedig lefuttatom az utkozes kiertekelott
checkCollision(_,[]):-!.
checkCollision(Obj,[HeadObj|EntityList]):- 
  (
    Obj \== HeadObj,
    object(Obj),
    object(HeadObj),
    get(Obj,attribute,posX,X1),
    get(Obj,attribute,posY,Y1),
    get(HeadObj,attribute,posX,X2),
    get(HeadObj,attribute,posY,Y2),
    X1 =:= X2,
    Y1 =:= Y2
  -> collision(Obj,HeadObj)
  ;true 
  ),
  checkCollision(Obj,EntityList).


collision(FirstObj,SecondObj):-
  %tesztelem hogy mindketto letezik e meg, arra az esetre ha a jatekos es kulcs egyszerre lepnek egymasra
  object(FirstObj),
  object(SecondObj),
  (
    get(FirstObj,attribute,collectedKeys,Ertek)
    %a FirstObj a jatekos
    -> UjErtek is Ertek+1, 
      send(FirstObj,attribute,collectedKeys,UjErtek),
      free(SecondObj)
    % a SecondObj a jatekos es a kulcs rament 
    ; get(SecondObj,attribute,collectedKeys,Ertek)
    ->UjErtek is Ertek +1,
      send(SecondObj,attribute,collectedKeys,UjErtek),
      free(FirstObj)
      %else ag ha kulcsok talalkkoznak de ez nem igazan lehetseges 
    ; true
  ).

%beallitok egy handlert ami felveszi az osszes keyboard inputott es tovabbitja azt
setup_controls(Window, Matrix, CellWidth, CellHeight, PlayerObj,EntityList,GateList) :-
    send(Window, recogniser,
         handler(keyboard, message(@prolog, on_key, @event?key, PlayerObj, prolog(Matrix), CellWidth, CellHeight, Window,prolog(EntityList),prolog(GateList)))).

on_key(Key, PlayerObj, Matrix, CellWidth, CellHeight,Window,EntityList,GateList) :-
    writeln(lenyomva: Key),
    (   key_direction(Key, DX, DY)
        
    ->  writeln(DX),try_move(PlayerObj, DX, DY, Matrix,Window, CellWidth, CellHeight,EntityList,GateList)
    ;   true
    ).
  %tudasbazis a nyilakra es a WASD-re igy egyszerubb
key_direction('<cursor_up>', 0, -1).

key_direction('<cursor_down>', 0, 1).

key_direction('<cursor_left>', -1, 0).

key_direction('<cursor_right>', 1, 0).
