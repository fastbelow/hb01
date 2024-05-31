import React from 'react';

interface Props {
  text: string;
}

const LowString: React.FC<Props> = ({ text }) => {
  if(text === '' || text == undefined) return <span></span>;
  const truncatedText = `${text.slice(0, 4)}...${text.slice(-4)}`;

  return <span>{truncatedText}</span>;
};

export default LowString;