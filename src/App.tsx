import { ConnectButton, useCurrentAccount, useSignAndExecuteTransactionBlock, useSuiClientInfiniteQuery, useSuiClientQuery } from "@mysten/dapp-kit";
import { isValidSuiObjectId } from "@mysten/sui.js/utils";
import { Box, Container, Flex, Heading } from "@radix-ui/themes";
import { useMemo, useState } from "react";
import { Counter } from "./Counter";
import { CreateCounter } from "./CreateCounter";
import { useNetworkVariable } from "./networkConfig";
import { MoveStruct, SuiEvent } from "@mysten/sui.js/client";
import { HdRoomList } from "./hdtools";
import RoomCard from "./RoomCard";
import { RankList } from "./RankList";
import './app.css';
import { TransactionBlock } from "@mysten/sui.js/transactions";

function App() {
  const currentAccount = useCurrentAccount();
  const counterPackageId = useNetworkVariable("counterPackageId");
  const PACKAGE_ID = counterPackageId;
  const MODULE_NAME = "hdmv";
  const CREATE_FUNCTION_NAME = "create_room";
  const MODULE_EVENT_NewRoom = "NewRoomCapEv";
  const MODULE_EVENT_PRankList = "NewPRankListEv";
  const MODULE_EVENT_PlayerList = "NewPlayerListEv";
  const [showDialog, setShowDialog] = useState(false);
  const [RoomName, setRoomName] = useState('');
  const [selectedOption, setSelectedOption] = useState('Rock');
  const [selectedOption2, setSelectedOption2] = useState('Rock');

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

    console.log(RoomName);
    console.log(selectedOption);
    console.log(selectedOption2);

    let txb = new TransactionBlock();
        txb.moveCall({
            target: `${PACKAGE_ID}::${MODULE_NAME}::${CREATE_FUNCTION_NAME}`,
            arguments: [
                txb.pure.string(RoomName),
                txb.pure.string(selectedOption),
                txb.pure.string(selectedOption2),
            ],
        });


        txb.setSender(currentAccount!.address);

        signAndExecuteTransactionBlock(
            {
              transactionBlock: txb,
              options: {
                showObjectChanges: true,
              },
            },
            {
                async onSuccess(data) {
                console.log("create success");
                console.log(data);
                alert("create success");
                // setSearcherRedPacket(undefined);
                // setIsSending(false);
                await refetchEvents();
                // await refetchDeTaskList();

                // enqueueSnackbar("Create task Success", {
                //   variant: "success",
                // });
              },
              onError() {
                console.log("create error");
                alert("create error");
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
  // const [counterId, setCounter] = useState(() => {
  //   const hash = window.location.hash.slice(1);
  //   return isValidSuiObjectId(hash) ? hash : null;
  // });

  //事件查询
  const {
    data: detaskEvents,
    refetch: refetchEvents,
    fetchNextPage,
    hasNextPage,
  } = useSuiClientInfiniteQuery(
    "queryEvents",
    {
      query: {
        MoveModule: {
          package: PACKAGE_ID,
          module: MODULE_NAME,
        },
      },
      order: "descending",
    },
    {
      refetchInterval: 10000,
    }
  );

  //获取 room 列表
  const newRoomEvents = useMemo(() => {
    return (
      detaskEvents?.pages.map((pEvent) =>
        pEvent.data.filter((event) => event.type.includes(MODULE_EVENT_NewRoom))
      ) || []
    ).flat(Infinity) as SuiEvent[];
  }, [detaskEvents]);
  
  
  let nowRoomList = [];
  if(newRoomEvents){
    console.log("newRoomEvents", newRoomEvents);
    
    nowRoomList = newRoomEvents?.map((obj:any) =>{
      let nowJson = obj as unknown as any;
      let Roomid = nowJson?.parsedJson?.id;
      return Roomid;
    });
    console.log("Roomid:", nowRoomList);
  }

  const newRankListEvents = useMemo(() => {
    return (
      detaskEvents?.pages.map((pEvent) =>
        pEvent.data.filter((event) => event.type.includes(MODULE_EVENT_PRankList))
      ) || []
    ).flat(Infinity) as SuiEvent[];
  }, [detaskEvents]);
  if(newRankListEvents){
    console.log("newRankListEvents", newRankListEvents);
    let nowlist = newRankListEvents[0] as any;
    let Ranklistid = nowlist?.parsedJson?.id;
    console.log("Ranklistid:", Ranklistid);
    localStorage.setItem("Ranklistid", Ranklistid);
  }

  //NewPlayerListEv
  const newPlayerListEvents = useMemo(() => {
    return (
      detaskEvents?.pages.map((pEvent) =>
        pEvent.data.filter((event) => event.type.includes(MODULE_EVENT_PlayerList))
      ) || []
    ).flat(Infinity) as SuiEvent[];
  }, [detaskEvents]);
  if(newPlayerListEvents){
    console.log("newPlayerListEvents", newPlayerListEvents);
    let nowplayerlist = newPlayerListEvents[0] as any;
    let Playerlistid = nowplayerlist?.parsedJson?.id;
    console.log("Playerlistid:", Playerlistid);
    localStorage.setItem("Playerlistid", Playerlistid);
  }
  
  //获取数据
  const { data: multi, refetch: refetchRoomList } = useSuiClientQuery(
    "multiGetObjects",
    {
      ids:
      nowRoomList || [],
      options: {
        showContent: true,
      },
    },
    {
      enabled: nowRoomList && nowRoomList.length > 0,
      // refetchInterval: 10000,
    }
  );

  const hdRoomList = useMemo(() => {
    return (
      multi
        ?.filter((i) => i.data?.content?.dataType === "moveObject")
        .map((obj) => {
          let content = obj.data?.content as {
            dataType: "moveObject";
            fields: MoveStruct;
            hasPublicTransfer: boolean;
            type: string;
          };
          return content.fields as unknown as HdRoomList;
        })
    );
  }, [multi]);
  // if(hdRoomList){
  //   console.log("hdRoomList", hdRoomList);
  // }

  return (
    <>
      <Flex
        position="sticky"
        px="4"
        py="2"
        justify="between"
        style={{
          borderBottom: "1px solid var(--gray-a2)",
        }}
      >
        <Box>
          {/*Sui Handbattle 1.0 testnet */}
          <Heading>Sui 环形掌上战争 1.0 测试网</Heading>
        </Box>

        <Box>
          <ConnectButton />
        </Box>
      </Flex>
      <Flex>
        <Box>
          <button className="createbutton" onClick={handleOpenDialog}>创建</button>
          {showDialog && (
            <div className='topDialog' style={{ position: 'fixed', top: '20%', left: '50%', transform: 'translateX(-50%)', border: '1px solid black', padding: '20px', backgroundColor: 'black' }}>
              <form onSubmit={handleSubmit}>
                <div className='dialogTitle'>创建房间</div>
                <div>
                <label className='llabel'>房间名称:</label>
                <input type="text" value={RoomName} onChange={e => setRoomName(e.target.value)} required /><br />
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
        </Box>
        <Box mr="4">
          <Container>
            <Heading>混战组列表</Heading>
            {
              hdRoomList?.map((item, index) => (
                  <RoomCard roomData={item} 
                  refetchEvents={refetchEvents}
                  refetchRoomList={refetchRoomList}
                  />
              ))
            }
          </Container>
        </Box>

        <Box>
          <Container>
            <Heading>排行榜</Heading>
            {/* 这里放置排行榜的内容 */}
            <RankList></RankList>
          </Container>
        </Box>
      </Flex>
    </>
  );
}

export default App;
function signAndExecuteTransactionBlock(arg0: { transactionBlock: TransactionBlock; options: { showObjectChanges: boolean; }; }, arg1: { onSuccess(data: any): Promise<void>; onError(): void; }) {
  throw new Error("Function not implemented.");
}

