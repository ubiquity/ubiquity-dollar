import Spinner from "./Spinner";

const Loading = ({ text = "Loading..." }: { text: string }): JSX.Element => (
  <div>
    <span>{text}</span>
    <span>{Spinner}</span>
  </div>
);

export default Loading;
