import $ from 'jquery';

// Expose jQuery so specs using jQuery plugins can be imported nicely.
// Here is an issue to explore better alternatives:
// https://gitlab.com/gitlab-org/gitlab/issues/12448
global.$ = $;
global.jQuery = $;

export default $;
