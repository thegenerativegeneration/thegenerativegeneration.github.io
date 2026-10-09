// Publication entries: the abstract, award and bibtex panels toggle and are mutually exclusive.
$(document).ready(function () {
  const panels = ["abstract", "award", "bibtex"];
  $(".pub .chips button.abstract, .pub .chips button.award, .pub .chips button.bibtex").click(function () {
    const clicked = panels.find((kind) => $(this).hasClass(kind));
    const entry = $(this).closest(".pub__body");
    panels.forEach((kind) => {
      const panel = entry.find(`.${kind}.hidden`);
      const toggle = entry.find(`.chips button.${kind}`);
      const open = kind === clicked && !panel.hasClass("open");
      panel.toggleClass("open", open);
      toggle.attr("aria-expanded", String(open));
    });
  });
});
