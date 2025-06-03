document.addEventListener("DOMContentLoaded", function () {
  const logoLink = document.querySelector(".md-header__button.md-logo");
  if (logoLink) {
    logoLink.setAttribute("href", "/documentation/index.html");
  }
});
