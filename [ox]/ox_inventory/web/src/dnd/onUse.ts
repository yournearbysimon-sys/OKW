//import toast from "react-hot-toast";
import { fetchNui } from '../utils/fetchNui';

export const onUse = (item: any) => {
  //toast.success(`Use ${item.name}`);
  fetchNui('useItem', item);
};
