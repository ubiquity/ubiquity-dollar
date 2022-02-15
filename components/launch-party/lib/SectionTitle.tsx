const SectionTitle = ({ title, subtitle }: { title: string; subtitle: string }) => {
  return (
    <>
      <h2 className="m-0 mb-2 tracking-widest uppercase text-xl">
        <span className="border-0 border-b-2 border-solid border-white">{title}</span>
      </h2>
      <p className="m-0 mb-6 font-light tracking-wide">{subtitle}</p>
    </>
  );
};

export default SectionTitle;
