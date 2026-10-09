---
layout: page
permalink: /experiments/
title: experiments
description: Creative experiments, and projects to be.
nav: true
nav_order: 3
---
{% assign items = site.experiments | sort: 'importance', 'last' %}
<div class="card-grid">
  {% for e in items %}
    {% include card.liquid url=e.url img=e.img title=e.title meta=e.year description=e.description %}
  {% endfor %}
</div>
