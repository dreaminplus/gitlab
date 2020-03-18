export const tags = state => {
  // to show the loader inside the table we need to pass an empty array to gl-table whenever the table is loading
  // this is to take in account isLoading = true and state.tags =[1,2,3] during pagination and delete
  return state.isLoading ? [] : state.tags;
};

export const dockerBuildCommand = state => {
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  return `docker build -t ${state.config.repositoryUrl} .`;
};

export const dockerPushCommand = state => {
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  return `docker push ${state.config.repositoryUrl}`;
};

export const dockerLoginCommand = state => {
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  return `docker login ${state.config.registryHostUrlWithPort}`;
};
