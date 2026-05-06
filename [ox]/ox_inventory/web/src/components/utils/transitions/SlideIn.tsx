import React, { useRef } from 'react';
import { CSSTransition } from 'react-transition-group';

type SlideDirection = 'left' | 'right' | 'bottom';

interface Props {
  in?: boolean;
  direction: SlideDirection;
  children: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
  timeout?: number;
}

const classNamesByDirection: Record<SlideDirection, string> = {
  left: 'transition-slide-left',
  right: 'transition-slide-right',
  bottom: 'transition-slide-bottom',
};

const SlideIn: React.FC<Props> = ({ in: isVisible, direction, children, timeout = 170 }) => {
  const nodeRef = useRef(null);

  return (
    <CSSTransition
      nodeRef={nodeRef}
      in={isVisible}
      timeout={timeout}
      classNames={classNamesByDirection[direction]}
      unmountOnExit
    >
      {React.cloneElement(children, { ref: nodeRef })}
    </CSSTransition>
  );
};

export default SlideIn;
