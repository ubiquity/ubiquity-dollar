import Spinner from "./spinner";

const Loading = ({ text = "· · ·" }: { text: string }): JSX.Element => (
  <div>
    <span>{text}</span>
    <span>{Spinner}</span>
  </div>
);

export default Loading;
