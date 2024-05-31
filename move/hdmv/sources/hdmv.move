#[allow(unused_use)]

module hdmv::hdmv{
    use std::vector;
    use sui::event;
    use sui::object::{Self,UID,ID,uid_to_bytes};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self,utf8,String};
    use std::ascii::{Self, String as TString};
    use sui::clock::{Self, Clock};
    use sui::table;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::bag::{Self,Bag};
    use std::type_name;
    use sui::dynamic_object_field as ofield;
    use sui::dynamic_field as field;
    use hdmv::hdbase;
    use std::hash::sha2_256;
    use std::debug::{Self,print};
    
    //Random number seed error code
    const EInvalidSeed:u64 = 1001;

    //The total number of players in one round
    const LimitedPlayers:u64 = 10;

    //Total number of people on the leaderboard
    const LimitedRanks:u64 = 10;
    
    const CastRock:vector<u8> = b"Rock";
    
    const CastScissors:vector<u8> = b"Scissors";
    
    const CastPaper:vector<u8> = b"Paper";

    //Winning, drawing, and losing points
    const CWin:u64 = 3;
    const CDraw:u64 = 1;
    const CLoss:u64 = 0;

    //Game status
    const GameInit:u64  = 0;
    const GameStart:u64 = 1;
    const GameEnd:u64   = 2;

    const ERR_NOT_Game_Init:u64   = 1005;
    const ERR_NOT_Game_CastAT:u64   = 1006;
    const ERR_NOT_Game_CastDF:u64   = 1007;
    const ERR_HasAlreadyJoined:u64   = 1008;


    //Strategies adopted by players
    struct Cast has store,drop{
        user:address,
        at:String,
        df:String,
        flag:u64,
        ate:u64,
        dfe:u64,
    }

    //Competition room
    struct Room has key,store {//share object
        id:UID,
        roomname:String,
        creator:address,
        castList:table::Table<u64,Cast>, // cast list
        usrQueue:vector<u64>,
        usrBattle:vector<u64>,
        usrList:vector<address>,
        fightPlan:vector<FightQ>,
        flag:u64,//init|start|end
        starttime:u64,
        roundtime:u64,//60*1000
        limited:u64, //limited: must more than 3 players
        roundusers:u64,//more than X players then begin
    }

    //Offensive and defensive positions
    //[2,0],[0,1],[1,2]
    struct FightQ has store,drop{
        att:u64,//at idx
        def:u64,//df idx
    }
    
    #[allow(unused_field)]
    struct RankList has key,store{
        id:UID,
        usrScore:table::Table<u64,Player>, // user socre
    }

    #[allow(unused_field)]
    struct PlayerList has key,store{
        id:UID,
        usrno:   table::Table<address,u64>, // address | Number
        usrlist: table::Table<u64,Player>,  // Number | Player
    }

    #[allow(unused_field)]
    struct Player has store{
        player:address, 
        score:u64,
    }

    #[allow(unused_field)]
    struct Player2 has key,store{
        id:UID,
        player:address, 
        score:u64,
    }

    #[allow(unused_field)]
    struct Book has store{
        // id:UID,
        author:address, 
        price:u64,
        pb:Publisher,
    }

    #[allow(unused_field)]
    struct Publisher has key,store{
        id:UID,
        name:String,
        // base:Book,
    }

    //events
    struct NewRoomCapEv has copy, drop {
        id: ID,
    }

    struct NewPlayerListEv has copy, drop {
        id: ID,
    }

    struct NewPRankListEv has copy, drop {
        id: ID,
    }

    struct NewFightLogEv has copy, drop {
        roomid:ID,
        player:address,
        at:String,
        ate:u64,
    }
    
    #[allow(unused_function)]
    fun init(ctx:&mut TxContext){
        //PlayerList
        let id = object::new(ctx);
        let eid = object::uid_to_inner(&id);
        let playerList = PlayerList{
            id,
            usrno: table::new(ctx),
            usrlist: table::new(ctx),
        };

        transfer::public_share_object(playerList);

        event::emit(NewPlayerListEv{
            id:eid,
        });

        let rankid = object::new(ctx);
        let rankeid = object::uid_to_inner(&rankid);
        let ranklist = RankList{
            id:rankid,
            usrScore:table::new(ctx)
        };
        let nLenMax = LimitedRanks;
        //init ranks
        let idx = 0;
        let maxScore:u64 = 10;
        while(idx < nLenMax){
            let nowscore = maxScore - idx;
            let nowPlayer = Player{
                player: @0xAABB,
                score:nowscore
            };
            table::add(&mut ranklist.usrScore,idx,nowPlayer);
            idx = idx + 1;
        };

        transfer::public_share_object(ranklist);

        event::emit(NewPRankListEv{
            id:rankeid,
        });
    }

    fun isCast(tcast:String):bool{
        let mat = *std::string::bytes(&tcast);
        if(CastRock == mat || CastPaper == mat || CastScissors == mat){
            return true
        }
        else{
            return false
        }
    }

    //init game ,room name,at,df
    entry public fun create_room(
        roomname:String,//name
        at:String,df:String,//at,df
        ctx:&mut TxContext
    ){
        assert!(isCast(at) , ERR_NOT_Game_CastAT);
        assert!(isCast(df) , ERR_NOT_Game_CastDF);
        //init room
        let id = object::new(ctx);
        let eid = object::uid_to_inner(&id);
        let admin = tx_context::sender(ctx);

        let nRoom = Room{
            id,
            roomname,
            creator: admin,
            castList:table::new(ctx),
            usrQueue:vector::empty<u64>(),
            usrBattle:vector::empty<u64>(),
            usrList:vector::empty<address>(),
            fightPlan:vector::empty<FightQ>(),
            flag:0,
            starttime:0,
            roundtime:0,//60*1000
            limited:LimitedPlayers, //limited: must more than X players
            roundusers:0,//more than X players then begin ext
        };

        add_queue(&mut nRoom,at,df,ctx);

        //share room
        transfer::public_share_object(nRoom);

        //event room's init
        event::emit(NewRoomCapEv{
            id:eid,
        });
    }

    //joinroom
    entry public fun join_room(
        rank:&mut RankList,
        room:&mut Room,
        pl:&mut PlayerList,
        at:String,df:String,//at,df
        ctx:&mut TxContext
    ){
        let user = tx_context::sender(ctx);//publisher
        assert!(!vector::contains(&room.usrList, &user), ERR_HasAlreadyJoined);
        
        //if status skip
        assert!( room.flag == GameInit , ERR_NOT_Game_Init);
        assert!(isCast(at) , ERR_NOT_Game_CastAT);
        assert!(isCast(df) , ERR_NOT_Game_CastDF);

        //add room
        add_queue(room,at,df,ctx);
        //if Limited then start
        if(room.roundusers >= LimitedPlayers){
            startgame(rank,pl , room , ctx);
        }
    }

    //start game
    fun startgame(rank:&mut RankList,pl:&mut PlayerList,room:&mut Room,ctx:&mut TxContext){
        std::debug::print(&utf8(b"start game ... "));
        room.flag = GameStart;//start game
        //std::debug::print(room);
        //update game
        let nLeng = vector::length(&room.usrQueue);//get player number
        //update userlist PlayerList 
        while(nLeng > 0){
            
            //get randidx
            let rdIdx = randint(nLeng,ctx);
            // std::debug::print(&rdIdx);

            let nowV = *vector::borrow(&room.usrQueue,rdIdx);

            //std::debug::print(&nowV);

            vector::remove(&mut room.usrQueue,rdIdx);

            init_queue(&mut room.usrBattle,nowV);

            // _ = vector::pop_back(&mut nRoom.usrQueue);
            nLeng = vector::length(&room.usrQueue);
        };

        nLeng = vector::length(&room.usrBattle);
        let fIdx = 0;
        let _nowVF:u64 = 0;
        let _nextV:u64 = 0;
        while(fIdx < nLeng){
            //left & right
            _nowVF = *vector::borrow(&room.usrBattle,fIdx);

            if(fIdx + 1 == nLeng){
                _nextV = *vector::borrow(&room.usrBattle, 0);
            }
            else{
                _nextV = *vector::borrow(&room.usrBattle,fIdx + 1);
            };
            //attacker, defence
            let nfightq = FightQ{
                att:_nowVF,
                def:_nextV
            };
            vector::push_back(&mut room.fightPlan,nfightq);
            //std::debug::print(&nowV);

            fIdx = fIdx + 1;
        };
        std::debug::print(&room.fightPlan);

        fIdx = 0;
        nLeng = vector::length(&room.fightPlan);
        let roomid = object::uid_to_inner(&room.id);
        while(fIdx < nLeng){
            //run fight plan 
            let nowFightQ = vector::borrow(&room.fightPlan,fIdx);
            let nowCastL = table::borrow(&room.castList,nowFightQ.att);
            // std::debug::print(nowCastL);
            let nowCastR = table::borrow(&room.castList,nowFightQ.def);
            // std::debug::print(nowCastR);
            let nowturn = new_logic(nowCastL.at,nowCastR.df);
            std::debug::print(&nowturn);
            if(nowturn == CWin){
                std::debug::print(&utf8(b"update win ... "));
                updateplayer(pl,nowCastL,CWin);
                //event win 
                event::emit(NewFightLogEv{
                    roomid,
                    player:nowCastL.user,
                    at:nowCastL.at,
                    ate:CWin
                });
            };
            if(nowturn == CDraw){
                updateplayer(pl,nowCastL,CDraw);
                event::emit(NewFightLogEv{
                    roomid,
                    player:nowCastL.user,
                    at:nowCastL.at,
                    ate:CDraw
                });
                updateplayer(pl,nowCastR,CDraw);
                event::emit(NewFightLogEv{
                    roomid,
                    player:nowCastR.user,
                    at:nowCastR.at,
                    ate:CDraw
                });
            };
            if(nowturn == CLoss){
                updateplayer(pl,nowCastL,CLoss);
            };
            fIdx = fIdx + 1;
        };
        //update ranklist RankList
        updaterank(rank,pl,room);

    }

    fun updateplayer(pl:&mut PlayerList,cast:&Cast,cost:u64){
        let user = cast.user;
        //std::debug::print(&user);
        let havePlayer = table::contains(&pl.usrno,user);
        if(havePlayer){
            let useridx = *table::borrow(&pl.usrno,user);
            let player = table::borrow_mut(&mut pl.usrlist,useridx);
            if(user == player.player){
                player.score = player.score + cost;
            };
        }
        else{
            let player = Player{
                player:user,
                score:cost
            };
            let idx = table::length(&pl.usrno);
            table::add(&mut pl.usrno,user,idx);
            table::add(&mut pl.usrlist,idx,player);
            
        };
        //std::debug::print(pl);
    }

    fun updaterank(rank:&mut RankList,pl:&mut PlayerList,room:&mut Room){
        std::debug::print(&utf8(b"update rank ... "));
        let nLenMax = LimitedRanks;
        let castLen = table::length(&room.castList);
        std::debug::print(&castLen);

        let idx = 0;
        while(idx < castLen){
            let nowcast = table::borrow(&room.castList,idx);
            let nowuseraddress = nowcast.user;
            let useridx = table::borrow(&pl.usrno,nowuseraddress);
            let player = table::borrow_mut(&mut pl.usrlist,*useridx);
            let nowplayerscore = player.score;
            let nowplayeraddress = nowuseraddress;
            std::debug::print(&nowplayerscore);
            std::debug::print(&nowplayeraddress);

            //let nowrankLen = table::length(&rank.usrScore);
            let idx2 = 0;
            let findflag = 0;
            let fidx = 0;
            while(idx2 < nLenMax){
                let rankscoreplayer = table::borrow(&rank.usrScore,idx2);
                if(rankscoreplayer.score < nowplayerscore){
                    findflag = 1;
                    fidx = idx2;
                    break
                };
                if(rankscoreplayer.score == nowplayerscore){
                    findflag = 2;
                    fidx = idx2;
                };
                idx2 = idx2 + 1;
            };
            
            std::debug::print(&utf8(b"update rank find flag ... "));
            std::debug::print(&findflag);

            let _oldplayerscore = 0;
            let _oldplayeraddress = @0x00;
            
            let startidx = fidx;
            std::debug::print(&startidx);

            if(findflag == 1){
                while(startidx < nLenMax){
                    let splayer = table::borrow_mut(&mut rank.usrScore,startidx);
                    _oldplayerscore = splayer.score;
                    _oldplayeraddress = splayer.player;
                    splayer.score = nowplayerscore;
                    splayer.player = nowplayeraddress;
                    startidx = startidx + 1;
                    nowplayerscore = _oldplayerscore;
                    nowplayeraddress = _oldplayeraddress;
                }
            };
            if(findflag == 2){
                if(fidx != nLenMax - 1){
                    startidx = fidx + 1;
                    while(startidx < nLenMax){
                        let splayer = table::borrow_mut(&mut rank.usrScore,startidx);
                        _oldplayerscore = splayer.score;
                        _oldplayeraddress = splayer.player;
                        splayer.score = nowplayerscore;
                        splayer.player = nowplayeraddress;
                        startidx = startidx + 1;
                        nowplayerscore = _oldplayerscore;
                        nowplayeraddress = _oldplayeraddress;
                    }   
                };
            };
            idx = idx + 1;
        };
        room.flag = GameEnd; //game
        std::debug::print(room);
        // std::debug::print(rank);
        let rankLen = table::length(&rank.usrScore);
        idx = 0;
        while(idx < rankLen){
            let splayer = table::borrow_mut(&mut rank.usrScore,idx);
            std::debug::print(&splayer.player);
            std::debug::print(&splayer.score);
            idx = idx + 1;
        };
    }

    //add_queue
    public fun add_queue(
        room:&mut Room,
        at:String,df:String,
        ctx:&mut TxContext
    ){
        let user = tx_context::sender(ctx);
        //:utf8(b"df")
        let newCast = Cast{
            // id:object::new(ctx),
            user,
            at,
            ate:0,
            df,
            dfe:0,
            flag: 0,
        };

        //user No.
        let nowCount = vector::length(&room.usrQueue);
        // push_back
        vector::push_back(&mut room.usrQueue,nowCount);
        vector::push_back(&mut room.usrList,user);

        room.roundusers = vector::length(&room.usrQueue);

        //table add
        table::add(&mut room.castList,nowCount,newCast);

    }

    fun init_queue(queue : &mut vector<u64>, nv : u64){
        vector::push_back(queue,nv);
    }

    public fun randint(n: u64, ctx: &mut TxContext): u64 {
        let rnd_id = object::new(ctx);
        // std::debug::print(&rnd_id);
        let rnd = sha2_256(uid_to_bytes(&rnd_id));
        assert!(vector::length(&rnd) >= 16, EInvalidSeed);
        let m: u128 = 0;
        let i = 0;
        while (i < 16) {
            m = m << 8;
            let curr_byte = *vector::borrow(&rnd, i);
            m = m + (curr_byte as u128);
            i = i + 1;
        };
        let n_128 = (n as u128);
        let module_128 = m % n_128;
        let res = (module_128 as u64);
        object::delete(rnd_id);
        res
    }


    #[test_only]
    use sui::test_scenario;
    use std::ascii::string;

    //just for test game play
    public fun new_logic(at_cast:String,df_cast:String) : u64{
        
        let ret = CLoss;
        let mat = *std::string::bytes(&at_cast);
        let mdf = *std::string::bytes(&df_cast);
        if( mat == mdf){
            ret = CDraw;
        };
        // Rock > Scissors > Paper > Rock
        if( CastRock == mat && CastScissors == mdf){
            ret = CWin;
        };
        if( CastRock == mat && CastPaper == mdf){
            ret = CLoss;
        };
        if( CastScissors == mat && CastPaper == mdf){
            ret = CWin;
        };
        if( CastScissors == mat && CastRock == mdf){
            ret = CLoss;
        };
        if( CastPaper == mat && CastRock == mdf){
            ret = CWin;
        };
        if( CastPaper == mat && CastScissors == mdf){
            ret = CLoss;
        };
        ret
    }

    #[test]
    fun new_room(){
        let shareobject:address = @0xabc01;
        let looker:address = @0xBBBBCC;
        let looker2:address = @0xBBBBC2;
        let scenario:sui::test_scenario::Scenario = test_scenario::begin(looker);
        let nowctx : &mut TxContext = test_scenario::ctx(&mut scenario );
        let c = clock::create_for_testing(nowctx);
        let startms = 1000 * 1000;
        clock::increment_for_testing(&mut c, startms);

        //create room
        let nRoom = Room{
            id:object::new(nowctx),
            roomname:utf8(b"testroom"),
            creator: looker,
            castList:table::new(nowctx),
            usrQueue:vector::empty<u64>(),
            usrBattle:vector::empty<u64>(),
            usrList:vector::empty<address>(),
            fightPlan:vector::empty<FightQ>(),
            flag:0,
            starttime:0,
            roundtime:0,//60*1000
            limited:0, //limited: must more than 3 players
            roundusers:0,//more than X players then begin
        };

        add_queue(&mut nRoom,utf8(b"at"),utf8(b"df"),nowctx);

        test_scenario::end(scenario);

        // test 2
        let scenario2:sui::test_scenario::Scenario = test_scenario::begin(looker2);

        let nowctx2 : &mut TxContext = test_scenario::ctx(&mut scenario2 );

        add_queue(&mut nRoom,utf8(b"at"),utf8(b"df"),nowctx2);

        

        let ni = 2;
        while(ni < 5){
            init_queue(&mut nRoom.usrQueue,ni);
            ni = ni + 1;
        };

        std::debug::print(&nRoom.usrQueue);

        //clear queue
        let nLeng = vector::length(&nRoom.usrQueue);
        //std::debug::print(&nLeng);
        
        while(nLeng > 0){
            
            //get randidx
            let rdIdx = randint(nLeng,nowctx2);
            std::debug::print(&rdIdx);

            let nowV = *vector::borrow(&nRoom.usrQueue,rdIdx);

            //std::debug::print(&nowV);

            vector::remove(&mut nRoom.usrQueue,rdIdx);

            init_queue(&mut nRoom.usrBattle,nowV);

            // _ = vector::pop_back(&mut nRoom.usrQueue);
            nLeng = vector::length(&nRoom.usrQueue);
        };
        std::debug::print(&nRoom.usrQueue);
        std::debug::print(&nRoom.usrBattle);
        nLeng = vector::length(&nRoom.usrBattle);
        let fIdx = 0;
        let nowVF = 0;
        let nextV = 0;
        while(fIdx < nLeng){

            //left & right
            nowVF = *vector::borrow(&nRoom.usrBattle,fIdx);

            if(fIdx + 1 == nLeng){
                nextV = *vector::borrow(&nRoom.usrBattle, 0);
            }
            else{
                nextV = *vector::borrow(&nRoom.usrBattle,fIdx + 1);
            };

            let nfightq = FightQ{
                att:nowVF,
                def:nextV
            };
            vector::push_back(&mut nRoom.fightPlan,nfightq);
            //std::debug::print(&nowV);

            fIdx = fIdx + 1;
        };
        std::debug::print(&nRoom.fightPlan);

        //get first 
        let nowFightQ = vector::borrow(&nRoom.fightPlan,0);
        std::debug::print(nowFightQ);
        let nowCast = table::borrow(&nRoom.castList,0);
        std::debug::print(nowCast);

        print(&new_logic(
            utf8(CastPaper),
            utf8(CastPaper)
            )
            );
        print(&new_logic(
            utf8(CastPaper),
            utf8(CastRock),
            )
            );   
        print(&new_logic(
            utf8(CastRock),
            utf8(CastScissors),
            )
            );        
        // nLeng = 5;
        // let nowr = randint(nLeng,nowctx2);
        // print(&nowr);

        // nowr = randint(nLeng,nowctx2);
        // print(&nowr);
        // print(&nowr);

        // nowr = randint(nLeng,nowctx2);
        // print(&nowr);

        test_scenario::end(scenario2);

        // clock::increment_for_testing(&mut c, 8);
        // print(&clock::timestamp_ms(&c));
        // nowr = clock::timestamp_ms(&c) % nLeng;
        // print(&nowr);

        clock::destroy_for_testing(c);     
        transfer::public_transfer(nRoom,shareobject);

    }

    #[test]
    fun test_queue(){
        print(&utf8(b"queue start ..."));
        let looker:address = @0xBBBBCCDD01;
        let looker2:address = @0xBBBBCCDD02;
        let scenario:sui::test_scenario::Scenario = test_scenario::begin(looker);
        let ctx : &mut TxContext = test_scenario::ctx(&mut scenario );
        //test init
        init(ctx);
        create_room(utf8(b"troom01"),utf8(b"Rock"),utf8(b"Scissors"),ctx);
        
        let effects = test_scenario::next_tx(&mut scenario,looker);
        let events = test_scenario::num_user_events(&effects);
        print(&events);

        let playerList = test_scenario::take_shared<PlayerList>(&scenario);
        print(&playerList);

        let rankList = test_scenario::take_shared<RankList>(&scenario);
        print(&rankList);
        
        let room = test_scenario::take_shared<Room>(&scenario);

        effects = test_scenario::next_tx(&mut scenario,looker);

        // add_queue(&mut room,utf8(b"Rock"),utf8(b"Scissors"),ctx);
        test_scenario::end(scenario);

        // test 2
        let scenario2:sui::test_scenario::Scenario = test_scenario::begin(looker2);
        let ctx2 : &mut TxContext = test_scenario::ctx(&mut scenario2 );

        //join_room2(&mut rankList,&mut room,&mut playerList,utf8(b"Rock"),utf8(b"Scissors"),ctx2);
        join_room(&mut rankList,&mut room,&mut playerList,utf8(b"Rock"),utf8(b"Scissors"),ctx2);

        // effects = test_scenario::next_tx(&mut scenario2,looker2);
        // print(&room);
        // print(ctx2);
        
        // let shares = test_scenario::shared(&effects);
        // print(&shares);

        // let share_obj1 = test_scenario::take_shared_by_id<PlayerList>(&scenario,shares[0]);
        // print(&share_obj1);
        // let shareobject:address = @0xabc01;
        print(&room);

        let Room{id:rid,
        roomname:_,
        creator:_,
        castList, 
        usrQueue:_,
        usrBattle:_,
        usrList:_,
        fightPlan:_,
        flag:_,
        starttime:_,
        roundtime:_,
        limited:_, 
        roundusers:_,
        } = room;
        table::drop(castList);
        
        object::delete(rid);

        let player2 = Player2{
            id:object::new(ctx2),
            player:@0x111,
            score:1};

        let Player2{id,player:_,score:_} = player2;
        object::delete(id);


        // test_scenario::return_shared<Room>(room);
        test_scenario::return_shared<PlayerList>(playerList);
        test_scenario::return_shared<RankList>(rankList);

        test_scenario::end(scenario2);
        
    }

}
