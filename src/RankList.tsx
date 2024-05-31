import { useSuiClientQueries, useSuiClientQuery } from "@mysten/dapp-kit";
import { useNetworkVariable } from "./networkConfig";
import { useMemo } from "react";
import LowString from "./LowString.tsx";
import './RankList.css'

export const RankList = () => {
    const counterPackageId = useNetworkVariable("counterPackageId");
    const PACKAGE_ID = counterPackageId;
    const MODULE_NAME = "hdmv";

    let Ranklistid = localStorage.getItem("Ranklistid");
    
    //获取RankList
    const { data: ObjectRankList } = useSuiClientQuery(
        "getObject",
        {
          id: Ranklistid as string,
          options: {
            showContent: true,
            showOwner: false,
          },
        },
    );
    // if(ObjectRankList){
    //     console.log(ObjectRankList);
    // }
    const RanklistId = useMemo(() => {
        let ndata = ObjectRankList?.data as any;
        console.log("Ranklist data is ", ndata);
        return ndata?.content?.fields?.usrScore?.fields?.id.id;
      }, [ObjectRankList]);
    if(RanklistId){
        console.log("Ranklist is ", RanklistId);
    }

    return <CompRankList RanklistId={RanklistId}/>
}

interface CompRankListProps {
    RanklistId: any;
}

const CompRankList: React.FC<CompRankListProps> = ({
    RanklistId
}) => {
    const { data: tbRanklistType, refetch: refetchEvents } = useSuiClientQuery(
        "getDynamicFields",
        {
          parentId: RanklistId as string,
        },
      );
      if (tbRanklistType) {
        console.log("tbRanklistType", tbRanklistType);
      }
      const tbRanklistTypelist: any = useMemo(() => {
        return tbRanklistType?.data.map((obj: any) => {
          let nowfields = [obj.name.type, obj.name.value] as any;
          return nowfields;
        });
      }, [tbRanklistType]);

      let nowtasklisttype = [] as any;
      if (tbRanklistTypelist) {
        // console.log("tbTasktypelist", tbTasktypelist);
        tbRanklistTypelist.forEach((item: any) => {
          //console.log("item####", item);
          const obj = {
            method: "getDynamicFieldObject",
            params: {
              parentId: RanklistId as string,
              name: {
                type: item[0],
                value: item[1],
              }
            }
          };
          nowtasklisttype.push(obj);
        });
        console.log("nowtasklisttype", nowtasklisttype);
      }
  

      return <CompRankListFO
      RanklistId={RanklistId}
      tbTasktypelist={nowtasklisttype}
      refetchEvents={refetchEvents}
    />;

}

interface CompRankListFOProps {
    RanklistId: any;
    tbTasktypelist: any;
    refetchEvents: any;
}

const CompRankListFO: React.FC<CompRankListFOProps> = ({
    RanklistId,tbTasktypelist, refetchEvents
}) => {
    
    const { data: tbRanklistDetails } = useSuiClientQueries({
        queries: tbTasktypelist,
        combine: (result) => {
          return {
            data: result.map((res) => res.data),
          }
        }
      });
    
    if (tbRanklistDetails) {
        console.log("tbRanklistDetails", tbRanklistDetails);
    }
    const ayRankItemidList = useMemo(() => {
        //   if(dataDetails.length > 0){
        const calTasklist = tbRanklistDetails?.map((obj: any) => {
          let nowfields = obj?.data?.content.fields.value.fields;
          return nowfields;
        });
        return calTasklist;
      }, [tbRanklistDetails]);
    
    //   if (ayRankItemidList) {
    //     console.log("ayRankItemidList", ayRankItemidList);
    //   }
    
    ayRankItemidList.sort((a, b) => b.score - a.score);

      // ayRankItemidList.forEach((item) => {
      //   console.log("item", item);
      // });
    return (
        <>
        {
          ayRankItemidList?.map((item: any, index) => (
              <div key={index}>
                <span className="username">
                  <LowString text={item?.player} />
                </span>
                <span className="scorename">
                  得分 : {item?.score}
                </span>
              </div>
            ))
        }
        </>
    )
  }