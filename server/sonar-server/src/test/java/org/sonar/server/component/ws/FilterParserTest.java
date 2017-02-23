/*
 * SonarQube
 * Copyright (C) 2009-2017 SonarSource SA
 * mailto:info AT sonarsource DOT com
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
package org.sonar.server.component.ws;

import java.util.List;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;
import org.sonar.server.component.ws.FilterParser.Criterion;

import static java.util.Arrays.asList;
import static java.util.Collections.emptyList;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;
import static org.sonar.server.component.ws.FilterParser.Operator.EQ;
import static org.sonar.server.component.ws.FilterParser.Operator.GT;
import static org.sonar.server.component.ws.FilterParser.Operator.GTE;
import static org.sonar.server.component.ws.FilterParser.Operator.IN;
import static org.sonar.server.component.ws.FilterParser.Operator.LT;
import static org.sonar.server.component.ws.FilterParser.Operator.LTE;

public class FilterParserTest {

  @Rule
  public ExpectedException expectedException = ExpectedException.none();

  @Test
  public void parse_filter_having_operator_and_value() throws Exception {
    List<Criterion> criterion = FilterParser.parse("ncloc > 10 and coverage <= 80");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("ncloc", GT, "10"),
        tuple("coverage", LTE, "80"));
  }

  @Test
  public void parse_filter_having_operator_and_value_ignores_white_spaces() throws Exception {
    List<Criterion> criterion = FilterParser.parse("   ncloc    >    10   ");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("ncloc", GT, "10"));
  }

  @Test
  public void parse_filter_having_in_operator() throws Exception {
    List<Criterion> criterion = FilterParser.parse("ncloc in (80,90)");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValues, Criterion::getValue)
      .containsOnly(
        tuple("ncloc", IN, asList("80", "90"), null));
  }

  @Test
  public void parse_filter_having_in_operator_ignores_white_spaces() throws Exception {
    List<Criterion> criterion = FilterParser.parse("  ncloc  in (  80 ,  90  )  ");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValues, Criterion::getValue)
      .containsOnly(
        tuple("ncloc", IN, asList("80", "90"), null));
  }

  @Test
  public void parse_filter_having_only_key() throws Exception {
    List<Criterion> criterion = FilterParser.parse("isFavorite");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("isFavorite", null, null));
  }

  @Test
  public void parse_filter_having_only_key_ignores_white_spaces() throws Exception {
    List<Criterion> criterion = FilterParser.parse("  isFavorite   ");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("isFavorite", null, null));
  }

  @Test
  public void parse_filter_having_different_criterion_types() throws Exception {
    List<Criterion> criterion = FilterParser.parse(" ncloc  > 10 and  coverage <= 80 and isFavorite ");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("ncloc", GT, "10"),
        tuple("coverage", LTE, "80"),
        tuple("isFavorite", null, null));
  }

  @Test
  public void parse_filter_with_key_having_underscore() throws Exception {
    List<Criterion> criterion = FilterParser.parse(" alert_status = OK");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("alert_status", EQ, "OK"));
  }

  @Test
  public void parse_filter_without_any_space_in_criteria() throws Exception {
    List<Criterion> criterion = FilterParser.parse("ncloc>10 and coverage<=80 and language in (java,js)");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue, Criterion::getValues)
      .containsOnly(
        tuple("ncloc", GT, "10", emptyList()),
        tuple("coverage", LTE, "80", emptyList()),
        tuple("language", IN, null, asList("java", "js")));
  }

  @Test
  public void parse_filter_having_all_operators() throws Exception {
    List<Criterion> criterion = FilterParser.parse("ncloc < 10 and coverage <= 80 and debt > 50 and duplication >= 56.5 and security_rating = 1 and language in (java,js)");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue, Criterion::getValues)
      .containsOnly(
        tuple("ncloc", LT, "10", emptyList()),
        tuple("coverage", LTE, "80", emptyList()),
        tuple("debt", GT, "50", emptyList()),
        tuple("duplication", GTE, "56.5", emptyList()),
        tuple("security_rating", EQ, "1", emptyList()),
        tuple("language", IN, null, asList("java", "js")));
  }

  @Test
  public void parse_filter_starting_and_ending_with_double_quotes() throws Exception {
    assertThat(FilterParser.parse("q = \"Sonar Qube\""))
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("q", EQ, "Sonar Qube"));

    assertThat(FilterParser.parse("q = \"Sonar\"Qube\""))
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("q", EQ, "Sonar\"Qube"));

    assertThat(FilterParser.parse("q = Sonar\"Qube"))
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("q", EQ, "Sonar\"Qube"));

    assertThat(FilterParser.parse("q=\"Sonar Qube\""))
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("q", EQ, "Sonar Qube"));
  }

  @Test
  public void accept_empty_query() throws Exception {
    List<Criterion> criterion = FilterParser.parse("");

    assertThat(criterion).isEmpty();
  }

  @Test
  public void accept_key_ending_by_in() throws Exception {
    List<Criterion> criterion = FilterParser.parse("endingbyin > 10");

    assertThat(criterion)
      .extracting(Criterion::getKey, Criterion::getOperator, Criterion::getValue)
      .containsOnly(
        tuple("endingbyin", GT, "10"));
  }

  @Test
  public void search_is_case_insensitive() throws Exception {
    List<Criterion> criterion = FilterParser.parse("ncloc > 10 AnD coverage <= 80 AND debt = 10 AND issues = 20");

    assertThat(criterion).hasSize(4);
  }

}