import Spinner from "./Spinner";

const Loading = ({ text = "Loading..." }: { text: string }): JSX.Element => (
  <div className="flex h-20 items-center justify-center text-lg text-white text-opacity-25">
    <span className="mr-4">{text}</span>
    <span className="scale-150">{Spinner}</span>
  </div>
);

export default Loading;
