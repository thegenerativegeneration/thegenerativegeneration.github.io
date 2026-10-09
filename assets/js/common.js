// Publication entries: the abstract, award and bibtex panels toggle and are mutually exclusive.
$(document).ready(function () {
  const panels = ["abstract", "award", "bibtex"];
  $("a.abstract, a.award, a.bibtex").click(function () {
    const clicked = panels.find((kind) => $(this).hasClass(kind));
    const entry = $(this).parent().parent();
    panels.forEach((kind) => {
      const panel = entry.find(`.${kind}.hidden`);
      if (kind === clicked) panel.toggleClass("open");
      else panel.removeClass("open");
    });
  });
});
