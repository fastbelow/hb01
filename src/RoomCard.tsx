import { useState } from 'react';
import './RoomCard.css'

import {
    useCurrentAccount, useSignAndExecuteTransactionBlock,
} from "@mysten/dapp-kit";
import { useNetworkVariable } from './networkConfig';
import { TransactionBlock } from '@mysten/sui.js/transactions';

interface roomProps {
    roomData: any;
    refetchEvents:any;
    refetchRoomList:any;
}


const RoomCard = ({ roomData,refetchEvents,refetchRoomList }: roomProps) => {
    const  account = useCurrentAccount();
    const counterPackageId = useNetworkVariable("counterPackageId");
    const PACKAGE_ID = counterPackageId;
    const MODULE_NAME = "hdmv";
    const JOIN_FUNCTION_NAME = "join_room";
  
    console.log("roomData", roomData);
    console.log("account", account);
    const [showDialog, setShowDialog] = useState(false);
    let nowUsers = roomData.usrQueue.length;
    let isCreator = roomData.creator === account?.address;
    let isLogin = account == null;
    let RoomName = roomData.roomname;
    const [selectedOption, setSelectedOption] = useState('Rock');
    const [selectedOption2, setSelectedOption2] = useState('Rock');
    let RoomStatus = roomData?.flag == 0 ? "等待中" : roomData?.flag == 1 ? "游戏中" : "已结束";
    let isJoin = roomData?.usrList.includes(account?.address);

    const handleSelectChange = (e:any) => {
        setSelectedOption(e.target.value);
        console.log(e.target.value);
      };
    
      const handleSelectChange2 = (e:any) => {
        setSelectedOption2(e.target.value);
        console.log(e.target.value);
      };
    
      const handleOpenDialog = () => {
        setShowDialog(true);
      };
    
      const handleCloseDialog = () => {
          setShowDialog(false);
          // 可选：清空输入字段  
          // setName('');
          // setDescription('');
          // setEmail('');
          // setExt('');
          // setTcount('');
          // setReward('');
          // setStTime('');
          // setEdTime('');
    
      };

      const { mutate: signAndExecuteTransactionBlock } =
        useSignAndExecuteTransactionBlock();
  
      const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        let Ranklistid = localStorage.getItem("Ranklistid");
        console.log("Ranklistid", Ranklistid);
        
        let Roomid = roomData.id.id;
        console.log("Roomid", Roomid);

        let Playerlistid = localStorage.getItem("Playerlistid");
        console.log("Playerlistid", Playerlistid);
        
        
        console.log(selectedOption);
        console.log(selectedOption2);
        
        let txb = new TransactionBlock();

        txb.moveCall({
            target: `${PACKAGE_ID}::${MODULE_NAME}::${JOIN_FUNCTION_NAME}`,
            arguments: [
                txb.object(Ranklistid as string),
                txb.object(Roomid as string),
                txb.object(Playerlistid as string),
                txb.pure.string(selectedOption),
                txb.pure.string(selectedOption2),
            ],
        });

        txb.setSender(account!.address);

        signAndExecuteTransactionBlock(
            {
              transactionBlock: txb,
              options: {
                showObjectChanges: true,
              },
            },
            {
                async onSuccess(data) {
                console.log("join game success");
                console.log(data);
                alert("Join room success");
                // setSearcherRedPacket(undefined);
                // setIsSending(false);
                await refetchEvents();
                await refetchRoomList();

                // enqueueSnackbar("Create task Success", {
                //   variant: "success",
                // });
              },
              onError() {
                console.log("join error");
                alert("join error");
                // setIsSending(false);
                // enqueueSnackbar("Create task Error", {
                //   variant: "error",
                // });
                // setSubmitting(false);
              },
            }
        );
        
        handleCloseDialog();
    };     
    return (
        <>
        <div className="room-card">
            <h1>混战组名: {roomData.roomname}</h1>
            <p>满员数: {roomData.limited} 当前人数: {nowUsers} {isCreator ? <>您是房主</> : null} {RoomStatus}</p>
            {
                isLogin === true ? (
                    <>尚未登录</>
                    ) : (
                        isCreator === false ? (
                          isJoin === false ? (
                            <button onClick={handleOpenDialog}>加入</button>
                          ) : (
                            <span>您已加入</span>
                          )
                    ) : null
                )
            }

        </div>
        {showDialog && (
            <div className='topDialog' style={{ position: 'fixed', top: '20%', left: '50%', transform: 'translateX(-50%)', border: '1px solid black', padding: '20px', backgroundColor: 'black' }}>
              <form onSubmit={handleSubmit}>
                <div className='dialogTitle'>加入房间</div>
                <div>
                    <label className='llabel'>房间名称:</label>
                    <input type="text" value={RoomName} readOnly /><br />
                </div>           
                <div className="attackinput">
                  <label className='llabel'>选择进攻策略:</label>
                  <select value={selectedOption} onChange={handleSelectChange}>
                    <option value="Rock">石头</option>
                    <option value="Paper">布</option>
                    <option value="Scissors">剪刀</option>
                  </select>
                </div>
                <div className="attackinput">
                  <label className='llabel'>选择防守策略:</label>
                  <select value={selectedOption2} onChange={handleSelectChange2}>
                    <option value="Rock">石头</option>
                    <option value="Paper">布</option>
                    <option value="Scissors">剪刀</option>
                  </select>
                </div>
                <button type="submit" className='okButton'>
                  OK
                </button>
                <button type="button" onClick={handleCloseDialog}>Cancel</button>

              </form>

            </div>
          )}
        </>
    );
};

export default RoomCard;

