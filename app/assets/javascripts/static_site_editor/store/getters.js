export const isContentLoaded = ({ originalContent }) => Boolean(originalContent);
export const contentChanged = ({ originalContent, content }) =>
  Boolean(content) && originalContent !== content;
