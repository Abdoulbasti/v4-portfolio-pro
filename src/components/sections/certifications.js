import React, { useEffect, useRef } from 'react';
import { srConfig } from '@config';
import sr from '@utils/sr';
import { usePrefersReducedMotion } from '@hooks';

const Certifications = () => {
  const revealContainer = useRef(null);
  const prefersReducedMotion = usePrefersReducedMotion();

  useEffect(() => {
    if (prefersReducedMotion) {
      return;
    }

    sr.reveal(revealContainer.current, srConfig());
  }, []);

  return (
    <section id="certifications" ref={revealContainer}>
      <h2 className="numbered-heading">Certifications</h2>
    </section>
  );
};

export default Certifications;
