import React, { useRef } from 'react';
import { CSSTransition } from 'react-transition-group';

interface Props {
  in?: boolean;
  children: React.ReactNode;
}

const Fade: React.FC<Props> = (props) => {
  const nodeRef = useRef(null);
  if (!React.isValidElement(props.children)) return null;

  const child = props.children as React.ReactElement<any, string | React.JSXElementConstructor<any>>;

  return (
    <CSSTransition in={props.in} nodeRef={nodeRef} classNames="transition-fade" timeout={200} unmountOnExit>
      {React.cloneElement(child, { ref: nodeRef })}
    </CSSTransition>
  );
};

export default Fade;
