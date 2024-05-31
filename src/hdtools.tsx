export interface HdRoomList {
    id: {
        id: string;
    };
    roomname:string;
    castList:any; // cast list
    usrQueue:any;
    usrBattle:any;
    fightPlan:any;
    flag:number;//init|start|end
    starttime:number;
    roundtime:number;//60*1000
    limited:number; //limited: must more than 3 players
    roundusers:number;//more than X players then begin
}