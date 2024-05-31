
interface Props {
    nowRoomlist: any;
}

export const RoomList: React.FC<Props> = ({
    nowRoomlist
}) => {
    return (
        <div>
            {nowRoomlist.map((item: any) => {
                return (
                    <p key={item.id}>{item.name}</p>
                );
            })}
        </div>
    )
}